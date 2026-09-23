import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../domain/models/room_model.dart';
import '../providers/room_provider.dart';
import 'widgets/create_room_dialog.dart';
import 'widgets/join_room_dialog.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  void _showCreateDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const CreateRoomDialog());
  }

  void _showJoinDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const JoinRoomDialog());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roomsState = ref.watch(roomsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Groups',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            Text(
              '${roomsState.rooms.length} active group${roomsState.rooms.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'Join with Code',
            onPressed: () => _showJoinDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create New Group',
            onPressed: () => _showCreateDialog(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(roomsNotifierProvider.notifier).loadRooms(),
        child: _buildBody(context, ref, roomsState, isDark),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Group', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.brandSky,
        foregroundColor: AppColors.brandNavy,
        elevation: 4,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    RoomsState state,
    bool isDark,
  ) {
    if (state.isLoading && state.rooms.isEmpty) {
      return const LoadingView(message: 'Loading groups...');
    }

    if (state.rooms.isEmpty) {
      return EmptyStateView(
        icon: Icons.groups_rounded,
        title: "No groups joined yet",
        description: 'Create a private group for your family, friends, or team, or join one using an invite code.',
        primaryActionLabel: 'Create Group',
        onPrimaryAction: () => _showCreateDialog(context),
        secondaryActionLabel: 'Join with Code',
        onSecondaryAction: () => _showJoinDialog(context),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Quick Action Row
        _buildActionHeader(context, isDark),
        const SizedBox(height: 16),

        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.sensors, size: 14, color: AppColors.brandSky),
              const SizedBox(width: 6),
              Text(
                'YOUR ACTIVE GROUPS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // List of Room Cards
        ...state.rooms.map((room) {
          final isSelected = state.currentRoom?.id == room.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRoomCard(context, ref, room, isSelected, isDark),
          );
        }),

        const SizedBox(height: 72), // Fab padding
      ],
    );
  }

  Widget _buildActionHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Create Circle Card
        Expanded(
          child: InkWell(
            onTap: () => _showCreateDialog(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'New Group',
                          style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Join Group Card
        Expanded(
          child: InkWell(
            onTap: () => _showJoinDialog(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.brandSky.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.brandSky.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.vpn_key_rounded, color: AppColors.brandSky, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'With Code',
                          style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCard(
    BuildContext context,
    WidgetRef ref,
    RoomModel room,
    bool isSelected,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        ref.read(roomsNotifierProvider.notifier).selectRoom(room);
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.statusOnline, size: 18),
                const SizedBox(width: 8),
                Text('Switched active group to "${room.name}"'),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.darkSurface,
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.brandSky
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brandSky.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Group Icon Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? AppColors.primaryGradient
                        : null,
                    color: isSelected
                        ? null
                        : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.groups_rounded,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),

                // Name and Members Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              room.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.brandSky.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.brandSky.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.radio_button_checked, size: 10, color: AppColors.brandSky),
                                  SizedBox(width: 4),
                                  Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: AppColors.brandSky,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${room.membersCount} member${room.membersCount == 1 ? '' : 's'}',
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

                // Options Menu
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () => _showRoomOptions(context, ref, room),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            const SizedBox(height: 12),

            // Bottom Row: Code with one-tap copy & Role Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: room.code));
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.copy, color: AppColors.brandSky, size: 16),
                            const SizedBox(width: 8),
                            Text('Group code ${room.code} copied!'),
                          ],
                        ),
                        backgroundColor: AppColors.darkSurface,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CODE: ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          room.code,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.brandSky,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.copy_rounded, size: 12, color: AppColors.brandSky),
                      ],
                    ),
                  ),
                ),

                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: room.isCurrentUserAdmin
                        ? AppColors.alertWarning.withValues(alpha: 0.12)
                        : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
                    borderRadius: BorderRadius.circular(6),
                    border: room.isCurrentUserAdmin
                        ? Border.all(color: AppColors.alertWarning.withValues(alpha: 0.4), width: 1)
                        : null,
                  ),
                  child: Text(
                    room.isCurrentUserAdmin ? '👑 ADMIN' : 'MEMBER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: room.isCurrentUserAdmin
                          ? AppColors.alertWarning
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRoomOptions(BuildContext context, WidgetRef ref, RoomModel room) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.copy_rounded, color: AppColors.brandSky),
                  title: const Text('Copy Group Invite Code', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(room.code),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: room.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Group code ${room.code} copied!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app_rounded, color: AppColors.alertEmergency),
                  title: const Text('Leave Group', style: TextStyle(color: AppColors.alertEmergency, fontWeight: FontWeight.w600)),
                  subtitle: const Text('You will stop sharing and receiving updates from this group'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        title: const Text('Leave Group'),
                        content: Text('Are you sure you want to leave "${room.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dCtx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dCtx, true),
                            child: const Text('Leave Group', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(roomsNotifierProvider.notifier).leaveRoom(room.id);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
