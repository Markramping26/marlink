import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marlink_app/core/services/global_notification_service.dart';
import 'package:marlink_app/core/services/notification_service.dart';
import 'package:marlink_app/core/services/pip_service.dart';
import 'package:marlink_app/core/theme/app_colors.dart';
import 'package:marlink_app/features/alerts/presentation/alerts_screen.dart';
import 'package:marlink_app/features/chat/presentation/call_screen.dart';
import 'package:marlink_app/features/chat/presentation/room_chat_screen.dart';
import 'package:marlink_app/features/chat/presentation/widgets/incoming_call_dialog.dart';
import 'package:marlink_app/features/chat/providers/call_provider.dart';
import 'package:marlink_app/features/map/presentation/live_map_screen.dart';
import 'package:marlink_app/features/profile/presentation/profile_screen.dart';
import 'package:marlink_app/features/rooms/presentation/rooms_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;
  StreamSubscription? _msgSub;
  bool _isIncomingDialogShowing = false;

  void _navigateToIndex(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Request notification permissions
      NotificationService.instance.requestPermission();

      // 2. Start global sync poller for calls and messages
      final globalService = ref.read(globalNotificationServiceProvider);
      globalService.start();

      // 3. Listen for in-app message notifications when not on the Chat tab
      _msgSub = globalService.incomingMessageStream.listen((msg) {
        if (_currentIndex != 2 && mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF0F1B35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.brandSky.withValues(alpha: 0.3)),
              ),
              content: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg.senderName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        ),
                        Text(
                          msg.content ?? (msg.isImage ? '📷 Photo' : '📍 Location pin'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              action: SnackBarAction(
                label: 'View',
                textColor: AppColors.brandSky,
                onPressed: () => _navigateToIndex(2),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    ref.read(globalNotificationServiceProvider).stop();
    super.dispose();
  }

  void _showIncomingCallModal(dynamic call) {
    if (_isIncomingDialogShowing) return;
    _isIncomingDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => IncomingCallDialog(call: call),
    ).then((_) {
      _isIncomingDialogShowing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final callState = ref.watch(callNotifierProvider);

    // Auto-display Incoming Call Dialog when an incoming call arrives
    ref.listen<CallState>(callNotifierProvider, (previous, next) {
      if (next.incomingCall != null &&
          (previous?.incomingCall?.id != next.incomingCall?.id || !_isIncomingDialogShowing)) {
        _showIncomingCallModal(next.incomingCall);
      } else if (next.incomingCall == null && _isIncomingDialogShowing) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        _isIncomingDialogShowing = false;
      }
    });

    final screens = [
      LiveMapScreen(
        onNavigateToChat: () => _navigateToIndex(2),
        onNavigateToAlerts: () => _navigateToIndex(3),
      ),
      const RoomsScreen(),
      RoomChatScreen(
        onOpenMapTab: () => _navigateToIndex(0),
      ),
      const AlertsScreen(),
      const ProfileScreen(),
    ];

    return ValueListenableBuilder<bool>(
      valueListenable: PipService.instance.isPipMode,
      builder: (context, isPip, child) {
        if (isPip) {
          // In Picture-in-Picture mode, only render the LiveMapScreen
          return screens[0];
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (_currentIndex != 0) {
              setState(() => _currentIndex = 0);
            } else {
              // On the Map screen: pressing Back enters Picture-in-Picture mode (Google Maps style)
              final entered = await PipService.instance.enterPip();
              if (!entered && mounted) {
                // If device does not support PiP, minimize to background
                SystemNavigator.pop();
              }
            }
          },
          child: Scaffold(
            body: Stack(
              children: [
                IndexedStack(
                  index: _currentIndex,
                  children: screens,
                ),

                // Floating Ongoing Call Chip (If call minimized)
                if (callState.activeCall != null && !callState.activeCall!.isEnded)
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CallScreen(call: callState.activeCall!),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1B35).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.statusOnline.withValues(alpha: 0.5),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.statusOnline,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                callState.activeCall!.isVideo ? Icons.videocam : Icons.phone_in_talk,
                                color: AppColors.statusOnline,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ongoing ${callState.activeCall!.isVideo ? "Video" : "Voice"} Call · ${callState.activeCall!.roomName}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.call_end, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  ref.read(callNotifierProvider.notifier).endCall();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: _navigateToIndex,
                backgroundColor: Colors.transparent,
                indicatorColor: isDark
                    ? AppColors.brandSky.withValues(alpha: 0.18)
                    : AppColors.brandBlue.withValues(alpha: 0.12),
                elevation: 0,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon: Icon(Icons.map, color: AppColors.brandSky),
                    label: 'Map',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.groups_outlined),
                    selectedIcon: Icon(Icons.groups_rounded, color: AppColors.brandSky),
                    label: 'Groups',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline),
                    selectedIcon: Icon(Icons.chat_bubble, color: AppColors.brandSky),
                    label: 'Chat',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.shield_outlined),
                    selectedIcon: Icon(Icons.shield, color: AppColors.brandSky),
                    label: 'Safety',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person, color: AppColors.brandSky),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
