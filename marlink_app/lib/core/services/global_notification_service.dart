import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/chat/domain/models/message_model.dart';
import '../../features/chat/providers/call_provider.dart';
import '../../features/chat/providers/chat_provider.dart';
import '../../features/rooms/providers/room_provider.dart';
import 'notification_service.dart';

final globalNotificationServiceProvider = Provider<GlobalNotificationService>((ref) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return GlobalNotificationService(ref, chatRepo);
});

class GlobalNotificationService {
  final Ref _ref;
  final ChatRepository _chatRepository;
  Timer? _syncTimer;
  final Set<int> _seenMessageIds = {};
  bool _isFirstLoad = true;

  // Stream controller for in-app message alerts when user is on another tab
  final StreamController<MessageModel> _incomingMessageStream =
      StreamController<MessageModel>.broadcast();
  Stream<MessageModel> get incomingMessageStream => _incomingMessageStream.stream;

  GlobalNotificationService(this._ref, this._chatRepository);

  void start() {
    _syncTimer?.cancel();
    _isFirstLoad = true;
    _seenMessageIds.clear();

    // Initial check
    _performSync();

    // Poll every 3.5 seconds
    _syncTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      _performSync();
    });
  }

  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _performSync() async {
    final authUser = _ref.read(authNotifierProvider).user;
    if (authUser == null) return;

    // 1. Sync Active/Incoming Calls
    try {
      await _ref.read(callNotifierProvider.notifier).syncActiveCall();
    } catch (e) {
      debugPrint('GlobalNotificationService: Call sync error: $e');
    }

    // 2. Sync Incoming Chat Messages
    final currentRoom = _ref.read(roomsNotifierProvider).currentRoom;
    if (currentRoom != null) {
      try {
        final messages = await _chatRepository.getMessages(currentRoom.id);
        if (_isFirstLoad) {
          for (final m in messages) {
            _seenMessageIds.add(m.id);
          }
          _isFirstLoad = false;
        } else {
          for (final m in messages) {
            if (!_seenMessageIds.contains(m.id)) {
              _seenMessageIds.add(m.id);

              // Only notify if message was sent by someone else
              if (m.userId != authUser.id) {
                final preview = m.content ?? (m.isImage ? '📷 Photo' : '📍 Location pin');
                
                // Show native heads-up system notification with chime sound
                NotificationService.instance.showChatMessage(
                  senderName: m.senderName,
                  message: preview,
                  roomName: currentRoom.name,
                  playSound: true,
                );

                // Broadcast for in-app floating banner
                _incomingMessageStream.add(m);

                // Add to chat state if loaded
                _ref.read(chatNotifierProvider.notifier).receiveIncomingMessage(m);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('GlobalNotificationService: Message sync error: $e');
      }
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _incomingMessageStream.close();
  }
}
