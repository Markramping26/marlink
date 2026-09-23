import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../rooms/providers/room_provider.dart';
import '../data/chat_repository.dart';
import '../domain/models/message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

class ChatState {
  final bool isLoading;
  final List<MessageModel> messages;
  final int? currentRoomId;
  final bool isSending;
  final String? errorMessage;

  const ChatState({
    this.isLoading = false,
    this.messages = const [],
    this.currentRoomId,
    this.isSending = false,
    this.errorMessage,
  });

  ChatState copyWith({
    bool? isLoading,
    List<MessageModel>? messages,
    int? currentRoomId,
    bool? isSending,
    String? errorMessage,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
    );
  }
}

final chatNotifierProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatNotifier(repository, ref);
});

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repository;
  final Ref _ref;
  Timer? _pollTimer;

  ChatNotifier(this._repository, this._ref) : super(const ChatState()) {
    loadMessages();
  }

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      loadMessages(silent: true);
    });
    loadMessages();
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> loadMessages({int? roomId, bool silent = false}) async {
    final targetRoom = _ref.read(roomsNotifierProvider).currentRoom;
    final targetId = roomId ?? targetRoom?.id;
    if (targetId == null) {
      state = state.copyWith(messages: [], currentRoomId: null, isLoading: false);
      return;
    }

    final isDifferentRoom = state.currentRoomId != targetId;
    if (isDifferentRoom) {
      // Clear out previous circle's messages immediately so they never mix!
      state = state.copyWith(
        isLoading: true,
        messages: [],
        currentRoomId: targetId,
        errorMessage: null,
      );
    } else if (!silent) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final messages = await _repository.getMessages(targetId);

      // Verify that this response is still for the currently active circle
      if (state.currentRoomId == targetId) {
        final currentUserId = _ref.read(authNotifierProvider).user?.id;
        if (state.messages.isNotEmpty && messages.isNotEmpty) {
          final latest = messages.first;
          final prevLatestId = state.messages.first.id;
          if (latest.id != prevLatestId && latest.userId != currentUserId) {
            NotificationService.instance.showChatMessage(
              senderName: latest.senderName,
              message: latest.content ?? (latest.messageType == 'image' ? '📷 Photo' : '📍 Location pin'),
              roomName: targetRoom?.name ?? 'Group',
            );
          }
        }

        state = state.copyWith(
          isLoading: false,
          messages: messages,
          currentRoomId: targetId,
        );
      }
    } catch (_) {
      if (state.currentRoomId == targetId) {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to load messages.');
      }
    }
  }

  Future<bool> sendTextMessage(String text) async {
    final currentRoom = _ref.read(roomsNotifierProvider).currentRoom;
    if (currentRoom == null || text.trim().isEmpty) return false;

    state = state.copyWith(isSending: true);
    try {
      final msg = await _repository.sendTextMessage(currentRoom.id, text.trim());
      state = state.copyWith(
        isSending: false,
        messages: [msg, ...state.messages],
      );
      return true;
    } catch (_) {
      state = state.copyWith(isSending: false);
      return false;
    }
  }

  Future<bool> sendLocationMessage(double lat, double lng, String label) async {
    final currentRoom = _ref.read(roomsNotifierProvider).currentRoom;
    if (currentRoom == null) return false;

    state = state.copyWith(isSending: true);
    try {
      final msg = await _repository.sendLocationMessage(
        currentRoom.id,
        latitude: lat,
        longitude: lng,
        label: label,
      );
      state = state.copyWith(
        isSending: false,
        messages: [msg, ...state.messages],
      );
      return true;
    } catch (_) {
      state = state.copyWith(isSending: false);
      return false;
    }
  }

  Future<bool> sendImage(File imageFile, String? caption) async {
    final currentRoom = _ref.read(roomsNotifierProvider).currentRoom;
    if (currentRoom == null) return false;

    state = state.copyWith(isSending: true);
    try {
      final msg = await _repository.sendImageMessage(currentRoom.id, imageFile, caption: caption);
      state = state.copyWith(
        isSending: false,
        messages: [msg, ...state.messages],
      );
      return true;
    } catch (_) {
      state = state.copyWith(isSending: false);
      return false;
    }
  }

  void receiveIncomingMessage(MessageModel msg) {
    if (!state.messages.any((m) => m.id == msg.id)) {
      state = state.copyWith(messages: [msg, ...state.messages]);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
