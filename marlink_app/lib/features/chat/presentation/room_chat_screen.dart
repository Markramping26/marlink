import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marlink_app/core/theme/app_colors.dart';
import 'package:marlink_app/core/widgets/empty_state_view.dart';
import 'package:marlink_app/core/widgets/loading_view.dart';
import 'package:marlink_app/features/auth/providers/auth_provider.dart';
import 'package:marlink_app/features/map/providers/location_provider.dart';
import 'package:marlink_app/features/rooms/presentation/widgets/group_members_sheet.dart';
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final authUser = ref.watch(authNotifierProvider).user;
            final sharingStatus = authUser?.profile?.sharingStatus ?? 'on';

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

                      // Fast-path: use cached position from active map tracking
                      final cachedPos = ref.read(mapNotifierProvider).myPosition;
                      if (cachedPos != null) {
                        ref.read(chatNotifierProvider.notifier).sendLocationMessage(
                              cachedPos.latitude,
                              cachedPos.longitude,
                              'My Current Location',
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('📍 Location pin sent to chat.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                        return;
                      }

                      // Fallback: acquire fresh coordinates
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
                          duration: Duration(seconds: 3),
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
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(mapNotifierProvider.notifier).setBroadcasting(true);
                      ref.read(authNotifierProvider.notifier).updateLocationSharing(status: 'on');
                      ref.read(chatNotifierProvider.notifier).sendTextMessage("🟢 Started sharing live location with room.");
                      ref.read(mapNotifierProvider.notifier).captureCurrentPosition(openSettingsIfDisabled: false);
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
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(mapNotifierProvider.notifier).setBroadcasting(true);
                      ref.read(authNotifierProvider.notifier).updateLocationSharing(status: 'on', durationMinutes: 60);
                      ref.read(chatNotifierProvider.notifier).sendTextMessage("⏱️ Started sharing live location for 1 hour.");
                      ref.read(mapNotifierProvider.notifier).captureCurrentPosition(openSettingsIfDisabled: false);
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
                    title: const Text('Pause Sharing (🟡 PAUSED)', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Keep room active but temporarily freeze GPS updates', style: TextStyle(fontSize: 12)),
                    trailing: sharingStatus == 'paused' ? const Icon(Icons.check_circle, color: AppColors.alertWarning) : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(mapNotifierProvider.notifier).setBroadcasting(false);
                      ref.read(authNotifierProvider.notifier).updateLocationSharing(status: 'paused');
                      ref.read(chatNotifierProvider.notifier).sendTextMessage("⏸️ Paused live location sharing.");
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
                      ref.read(chatNotifierProvider.notifier).sendTextMessage("🔴 Stopped sharing live location.");
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
        title: InkWell(
          onTap: currentRoom == null ? null : () => GroupMembersSheet.show(context, currentRoom),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
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
          ),
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
                            Text('Starting group voice call...'),
                          ],
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    final call = await ref
                        .read(callNotifierProvider.notifier)
                        .startCall(currentRoom.id, isVideo: false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      if (call != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CallScreen(call: call)),
                        );
                      } else {
                        final err = ref.read(callNotifierProvider).errorMessage ?? 'Unable to connect call. Please check your connection.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(err),
                            backgroundColor: AppColors.alertEmergency,
                          ),
                        );
                      }
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
                            Text('Starting group video call...'),
                          ],
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    final call = await ref
                        .read(callNotifierProvider.notifier)
                        .startCall(currentRoom.id, isVideo: true);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      if (call != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CallScreen(call: call)),
                        );
                      } else {
                        final err = ref.read(callNotifierProvider).errorMessage ?? 'Unable to connect video call. Please check your connection.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(err),
                            backgroundColor: AppColors.alertEmergency,
                          ),
                        );
                      }
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Group Options',
            onSelected: (val) async {
              if (currentRoom == null) return;
              if (val == 'members') {
                GroupMembersSheet.show(context, currentRoom);
              } else if (val == 'copy_code') {
                Clipboard.setData(ClipboardData(text: currentRoom.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Group code ${currentRoom.code} copied!')),
                );
              } else if (val == 'leave') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Row(
                      children: [
                        Icon(Icons.exit_to_app_rounded, color: AppColors.alertEmergency, size: 24),
                        SizedBox(width: 8),
                        Text('Leave Group'),
                      ],
                    ),
                    content: Text('Are you sure you want to leave "${currentRoom.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.alertEmergency,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(dCtx, true),
                        child: const Text('Leave Group'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Text('Leaving "${currentRoom.name}"...'),
                        ],
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  final success = await ref.read(roomsNotifierProvider.notifier).leaveRoom(currentRoom.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'You have left "${currentRoom.name}".'
                            : 'Failed to leave group. Please try again.'),
                        backgroundColor: success ? AppColors.statusOnline : AppColors.alertEmergency,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'members',
                child: Row(
                  children: [
                    Icon(Icons.people_alt_rounded, size: 18, color: AppColors.brandSky),
                    SizedBox(width: 10),
                    Text('Members & Manage'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy_code',
                child: Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 18, color: AppColors.brandSky),
                    SizedBox(width: 10),
                    Text('Copy Invite Code'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app_rounded, size: 18, color: AppColors.alertEmergency),
                    SizedBox(width: 10),
                    Text('Leave Group', style: TextStyle(color: AppColors.alertEmergency)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if ((authUser?.profile?.sharingStatus ?? 'on') == 'paused')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.alertWarning.withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(Icons.pause_circle_outline, color: AppColors.alertWarning, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Live location sharing is paused.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.alertWarning),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(mapNotifierProvider.notifier).setBroadcasting(true);
                      ref.read(authNotifierProvider.notifier).updateLocationSharing(status: 'on');
                      ref.read(chatNotifierProvider.notifier).sendTextMessage("🟢 Resumed live location sharing.");
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Resume', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.brandSky)),
                  ),
                ],
              ),
            ),
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
