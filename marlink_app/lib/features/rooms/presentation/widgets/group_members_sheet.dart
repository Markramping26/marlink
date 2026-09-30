import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/marlink_avatar.dart';
import '../../../../core/widgets/marlink_toast.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../chat/presentation/call_screen.dart';
import '../../../chat/providers/call_provider.dart';
import '../../data/room_repository.dart';
import '../../domain/models/room_member_model.dart';
import '../../domain/models/room_model.dart';
import '../../providers/room_provider.dart';

class GroupMembersSheet extends ConsumerStatefulWidget {
  final RoomModel room;

  const GroupMembersSheet({super.key, required this.room});

  static Future<void> show(BuildContext context, RoomModel room) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroupMembersSheet(room: room),
    );
  }

  @override
  ConsumerState<GroupMembersSheet> createState() => _GroupMembersSheetState();
}

class _GroupMembersSheetState extends ConsumerState<GroupMembersSheet> {
  RoomModel? _detailedRoom;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repo = RoomRepository();
      final fresh = await repo.getRoomDetails(widget.room.id);
      if (mounted) {
        setState(() {
          _detailedRoom = fresh;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _detailedRoom = widget.room;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _kickMember(RoomMemberModel member) async {
    final room = _detailedRoom ?? widget.room;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_remove_rounded, color: AppColors.alertEmergency, size: 24),
            SizedBox(width: 8),
            Text('Kick Member'),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            children: [
              const TextSpan(text: 'Are you sure you want to remove '),
              TextSpan(
                text: member.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' from '),
              TextSpan(
                text: room.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '? They will no longer have access to this group.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertEmergency,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kick Member'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    MarLinkToast.show(
      context,
      message: 'Removing ${member.displayName}...',
      type: MarLinkToastType.loading,
    );

    final success = await ref
        .read(roomsNotifierProvider.notifier)
        .removeMember(room.id, member.userId);

    if (!mounted) return;

    if (success) {
      MarLinkToast.showSuccess(context, '${member.displayName} has been removed from the group.');
      _loadMembers();
    } else {
      MarLinkToast.showError(context, 'Failed to remove member. Please try again.');
    }
  }

  Future<void> _leaveGroup() async {
    final room = _detailedRoom ?? widget.room;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: AppColors.alertEmergency, size: 24),
            SizedBox(width: 8),
            Text('Leave Group'),
          ],
        ),
        content: Text('Are you sure you want to leave "${room.name}"? You will stop sharing and receiving location updates from this group.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertEmergency,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave Group'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final nav = Navigator.of(context);

    final success = await ref.read(roomsNotifierProvider.notifier).leaveRoom(room.id);
    if (!mounted) return;

    if (success) {
      nav.pop(); // Close bottom sheet
      MarLinkToast.showSuccess(context, 'You have left "${room.name}".');
    } else {
      MarLinkToast.showError(context, 'Failed to leave group. Please check your connection.');
    }
  }

  Future<void> _startDirectCall(int targetUserId, {required bool isVideo}) async {
    final room = _detailedRoom ?? widget.room;
    final nav = Navigator.of(context);

    MarLinkToast.show(
      context,
      message: isVideo ? 'Starting direct video call...' : 'Starting direct voice call...',
      type: MarLinkToastType.loading,
    );

    final call = await ref.read(callNotifierProvider.notifier).startCall(
          room.id,
          isVideo: isVideo,
          targetUserId: targetUserId,
        );

    if (!mounted) return;

    if (call != null) {
      nav.push(
        MaterialPageRoute(builder: (_) => CallScreen(call: call)),
      );
    } else {
      final err = ref.read(callNotifierProvider).errorMessage ?? 'Unable to connect call.';
      MarLinkToast.showError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final room = _detailedRoom ?? widget.room;
    final currentUserId = ref.watch(authNotifierProvider).user?.id ?? 0;
    final isCurrentUserAdmin = room.isCurrentUserAdmin || (currentUserId > 0 && currentUserId == room.createdBy);

    final members = room.members;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 6),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.groups_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: room.code));
                                MarLinkToast.showInfo(context, 'Group code ${room.code} copied!');
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.brandSky.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      room.code,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.brandSky,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.copy_rounded, size: 10, color: AppColors.brandSky),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${members.isNotEmpty ? members.length : room.membersCount} member${(members.isNotEmpty ? members.length : room.membersCount) == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),

            // Admin badge info banner if admin
            if (isCurrentUserAdmin)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.brandSky.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.brandSky.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded, size: 18, color: AppColors.brandSky),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You are an Admin. You can manage and kick members from this group.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.brandSky),
                      ),
                    ),
                  ],
                ),
              ),

            // Members List
            Expanded(
              child: _isLoading && members.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : members.isEmpty
                      ? Center(
                          child: Text(
                            'No members found',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: members.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 64,
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          itemBuilder: (ctx, index) {
                            final member = members[index];
                            final isMe = member.userId == currentUserId;
                            final isMemberCreator = member.userId == room.createdBy || member.role == 'owner';
                            final canKick = isCurrentUserAdmin && !isMe && !isMemberCreator;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              leading: MarLinkAvatar(
                                name: member.displayName,
                                imageUrl: member.avatarUrl,
                                radius: 22,
                                showOnlineIndicator: true,
                                isOnline: member.isSharingActive,
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      member.displayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.brandSky.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'YOU',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.brandSky,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    '@${member.username}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Role Tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isMemberCreator
                                          ? AppColors.alertWarning.withValues(alpha: 0.15)
                                          : (member.role == 'admin'
                                              ? AppColors.brandSky.withValues(alpha: 0.15)
                                              : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isMemberCreator
                                          ? '👑 OWNER'
                                          : (member.role == 'admin' ? '🛡️ ADMIN' : 'MEMBER'),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: isMemberCreator
                                            ? AppColors.alertWarning
                                            : (member.role == 'admin'
                                                ? AppColors.brandSky
                                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isMe) ...[
                                    IconButton(
                                      icon: const Icon(Icons.call_rounded, size: 18, color: AppColors.statusOnline),
                                      tooltip: 'Voice Call ${member.displayName}',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _startDirectCall(member.userId, isVideo: false),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.videocam_rounded, size: 18, color: AppColors.brandSky),
                                      tooltip: 'Video Call ${member.displayName}',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _startDirectCall(member.userId, isVideo: true),
                                    ),
                                  ],
                                  if (canKick)
                                    IconButton(
                                      icon: const Icon(Icons.person_remove_rounded, size: 20, color: AppColors.alertEmergency),
                                      tooltip: 'Kick ${member.displayName}',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _kickMember(member),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),

            // Footer Actions
            Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.alertEmergency,
                        side: const BorderSide(color: AppColors.alertEmergency),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _leaveGroup,
                      icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                      label: const Text('Leave Group', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
