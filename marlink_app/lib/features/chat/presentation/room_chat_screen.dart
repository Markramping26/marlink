import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marlink_app/core/theme/app_colors.dart';
import 'package:marlink_app/core/widgets/empty_state_view.dart';
import 'package:marlink_app/core/widgets/loading_view.dart';
import 'package:marlink_app/features/auth/providers/auth_provider.dart';
import 'package:marlink_app/features/map/providers/location_provider.dart';
import 'package:marlink_app/features/rooms/providers/room_provider.dart';
import 'package:marlink_app/features/chat/providers/chat_provider.dart';
import 'package:marlink_app/features/chat/providers/call_provider.dart';
import 'call_screen.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/message_bubble.dart';

class RoomChatScreen extends ConsumerStatefulWidget {
  final VoidCallback? onOpenMapTab;

  const RoomChatScreen({super.key, this.onOpenMapTab});

  @override
  ConsumerState<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends ConsumerState<RoomChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatNotifierProvider.notifier).startPolling();
    });
  }

  @override
  void dispose() {
    ref.read(chatNotifierProvider.notifier).stopPolling();
    _scrollController.dispose();
    super.dispose();
  }

  void _showLocationOptionsSheet(BuildContext context) {
    final authUser = ref.read(authNotifierProvider).user;
    final sharingStatus = authUser?.profile?.sharingStatus ?? 'on';

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.brandSky, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Location Sharing & Privacy Controls',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 1. Instant Pin to Chat
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pin_drop, color: AppColors.brandBlue, size: 22),
                ),
                title: const Text('Pin Current Location to Chat', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Send an exact GPS coordinates map card to room members', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text('Acquiring high-accuracy GPS position...'),
                        ],
                      ),
                      duration: Duration(seconds: 4),
                    ),
                  );

                  final pos = await ref.read(mapNotifierProvider.notifier).captureCurrentPosition(openSettingsIfDisabled: true);
                  if (pos != null && context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ref.read(chatNotifierProvider.notifier).sendLocationMessage(
                          pos.latitude,
                          pos.longitude,
                          'My Current Location',
                        );
                  }
                },
              ),

              // 2. Share Live Location (Continuous)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.statusOnline.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sensors, color: AppColors.statusOnline, size: 22),
                ),
                title: const Text('Share Live Location (🟢 ON)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Stream real-time GPS coordinate updates on map', style: TextStyle(fontSize: 12)),
                trailing: sharingStatus == 'on' ? const Icon(Icons.check_circle, color: AppColors.statusOnline) : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(mapNotifierProvider.notifier).captureCurrentPosition(openSettingsIfDisabled: true);
                  ref.read(mapNotifierProvider.notifier).setBroadcasting(true);
                  ref.read(authNotifierProvider.notifier).updateLocationSharing(status: 'on');
                  ref.read(chatNotifierProvider.notifier).sendTextMessage("🟢 Started sharing live location with room.");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Live location sharing is now ACTIVE.')),
                    );
                  }
                },
              ),

              // 3. Share for 1 Hour
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandSky.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.timer_outlined, color: AppColors.brandSky, size: 22),
                ),
                title: const Text('Share for 1 Hour (⏱️ 60 Mins)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Stream GPS for 60 minutes, then automatically pause', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(mapNotifierProvider.notifier).captureCurrentPosition(openSettingsIfDisabled: true);
                  ref.read(mapNotifierProvider.notifier).setBroadcasting(true);
                  ref.read(authNotifierProvider.notifier).updateLocationSharing(status: 'on', durationMinutes: 60);
                  ref.read(chatNotifierProvider.notifier).sendTextMessage("⏱️ Started sharing live location for 1 hour.");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sharing live location for the next 1 hour.')),
                    );
                  }
                },
              ),

              // 4. Pause Sharing
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.alertWarning.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pause_circle_outline, color: AppColors.alertWarning, size: 22),
                ),
                title: const Text('Pause Sharing (⚪ PAUSED)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Keep room active but temporarily freeze GPS updates', style: TextStyle(fontSize: 12)),
                trailing: sharingStatus == 'paused' ? const Icon(Icons.check_circle, color: AppColors.alertWarning) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(mapNotifierProvider.notifier).setBroadcasting(false);
                  ref.read(authNotifierProvider.notifier).updateLocationSharing(status: 'paused');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location sharing is now PAUSED.')),
                    );
                  }
                },
              ),

              // 5. Turn Off Location
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.alertEmergency.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_off_outlined, color: AppColors.alertEmergency, size: 22),
                ),
                title: const Text('Turn Off Location (🔴 OFF)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Completely stop location broadcasting', style: TextStyle(fontSize: 12)),
                trailing: sharingStatus == 'off' ? const Icon(Icons.check_circle, color: AppColors.alertEmergency) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(mapNotifierProvider.notifier).setBroadcasting(false);
                  ref.read(authNotifierProvider.notifier).updateLocationSharing(status: 'off');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location broadcasting is turned OFF.')),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authNotifierProvider).user;
    final currentRoom = ref.watch(roomsNotifierProvider).currentRoom;
    final chatState = ref.watch(chatNotifierProvider);

    // Auto-reload circle chat whenever the active circle changes
    ref.listen<RoomsState>(roomsNotifierProvider, (previous, next) {
      if (previous?.currentRoom?.id != next.currentRoom?.id) {
        ref.read(chatNotifierProvider.notifier).loadMessages(roomId: next.currentRoom?.id);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.groups_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentRoom?.name ?? 'Group Chat',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (currentRoom != null)
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.statusOnline,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${currentRoom.membersCount} online · Code: ${currentRoom.code}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            icon: const Icon(Icons.call_rounded, color: AppColors.statusOnline),
            tooltip: 'Voice Call Group',
            onPressed: currentRoom == null
                ? null
                : () async {
                    final call = await ref
                        .read(callNotifierProvider.notifier)
                        .startCall(currentRoom.id, isVideo: false);
                    if (call != null && context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CallScreen(call: call)),
                      );
                    }
                  },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            icon: const Icon(Icons.videocam_rounded, color: AppColors.brandSky),
            tooltip: 'Video Call Group',
            onPressed: currentRoom == null
                ? null
                : () async {
                    final call = await ref
                        .read(callNotifierProvider.notifier)
                        .startCall(currentRoom.id, isVideo: true);
                    if (call != null && context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CallScreen(call: call)),
                      );
                    }
                  },
          ),
          if (widget.onOpenMapTab != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              icon: const Icon(Icons.map_outlined),
              tooltip: 'View on Live Map',
              onPressed: widget.onOpenMapTab,
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            icon: const Icon(Icons.share_location_outlined),
            tooltip: 'Location Sharing Options',
            onPressed: () => _showLocationOptionsSheet(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(chatState, authUser?.id),
          ),
          ChatInputBar(
            isSending: chatState.isSending,
            onSendText: (text) {
              ref.read(chatNotifierProvider.notifier).sendTextMessage(text);
            },
            onSendImage: (file) {
              ref.read(chatNotifierProvider.notifier).sendImage(file, null);
            },
            onSendLocation: () => _showLocationOptionsSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatState state, int? currentUserId) {
    if (state.isLoading && state.messages.isEmpty) {
      return const LoadingView(message: 'Loading messages...');
    }

    if (state.messages.isEmpty) {
      return const EmptyStateView(
        icon: Icons.chat_bubble_outline,
        title: 'No messages yet',
        description: 'Send a message, an image, or share your current location to start the room conversation.',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Newest at bottom
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final isMe = message.userId == currentUserId;

        return MessageBubble(
          message: message,
          isMe: isMe,
          onOpenLocation: () {
            widget.onOpenMapTab?.call();
          },
        );
      },
    );
  }
}
