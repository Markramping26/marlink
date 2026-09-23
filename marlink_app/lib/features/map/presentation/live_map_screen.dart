import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:marlink_app/core/config/app_config.dart';
import 'package:marlink_app/core/services/notification_service.dart';
import 'package:marlink_app/core/services/pip_service.dart';
import 'package:marlink_app/core/theme/app_colors.dart';
import 'package:marlink_app/core/utils/haversine_calculator.dart';
import 'package:marlink_app/core/widgets/marlink_avatar.dart';
import 'package:marlink_app/features/auth/providers/auth_provider.dart';
import 'package:marlink_app/features/chat/presentation/call_screen.dart';
import 'package:marlink_app/features/chat/providers/call_provider.dart';
import 'package:marlink_app/features/rooms/presentation/widgets/create_room_dialog.dart';
import 'package:marlink_app/features/rooms/presentation/widgets/join_room_dialog.dart';
import 'package:marlink_app/features/rooms/providers/room_provider.dart';
import 'package:marlink_app/features/map/domain/models/member_location_model.dart';
import 'package:marlink_app/features/map/providers/location_provider.dart';
import 'package:marlink_app/features/map/providers/tracing_provider.dart';
import 'package:marlink_app/features/alerts/domain/models/alert_model.dart';
import 'package:marlink_app/features/alerts/providers/alert_provider.dart';
import 'widgets/map_controls_widget.dart';
import 'widgets/member_details_bottom_sheet.dart';
import 'widgets/member_marker_widget.dart';

class LiveMapScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToChat;
  final VoidCallback? onNavigateToAlerts;

  const LiveMapScreen({
    super.key,
    this.onNavigateToChat,
    this.onNavigateToAlerts,
  });

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen> {
  final MapController _mapController = MapController();
  double _currentZoom = 15.0;

  @override
  void initState() {
    super.initState();
    PipService.instance.setAutoPip(true);
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authNotifierProvider).user;
    final roomState = ref.watch(roomsNotifierProvider);
    final mapState = ref.watch(mapNotifierProvider);
    final tracingState = ref.watch(tracingNotifierProvider);

    final currentRoom = roomState.currentRoom;
    final sharingStatus = authUser?.profile?.sharingStatus ?? 'on';
    final alertState = ref.watch(alertNotifierProvider);
    final currentUserId = authUser?.id;
    final selfAlert = alertState.activeAlerts.where((a) => a.senderId == currentUserId && a.isActive).firstOrNull;

    // Auto-refresh member locations whenever active group changes
    ref.listen<RoomsState>(roomsNotifierProvider, (previous, next) {
      if (previous?.currentRoom?.id != next.currentRoom?.id) {
        if (ref.read(tracingNotifierProvider).isTracing) {
          ref.read(tracingNotifierProvider.notifier).stopTracing();
        }
        ref.read(mapNotifierProvider.notifier).clearRoomLocations();
        ref.read(mapNotifierProvider.notifier).fetchRoomLocations();
      }
    });

    // Dynamically update traced member and road route when map updates
    ref.listen<MapState>(mapNotifierProvider, (previous, next) {
      final tState = ref.read(tracingNotifierProvider);
      if (tState.isTracing && next.myLatLng != null && tState.tracedMember != null) {
        // Sync traced member to latest coordinates & speed from room
        try {
          final updated = next.memberLocations.firstWhere(
            (m) => m.userId == tState.tracedMember!.userId,
          );
          ref.read(tracingNotifierProvider.notifier).updateTracedMember(updated);
        } catch (_) {}

        if (tState.isNavigationFollowMode) {
          _mapController.move(next.myLatLng!, 17.5);
        }

        final targetLatLng = LatLng(tState.tracedMember!.latitude, tState.tracedMember!.longitude);

        // Recalculate route if moved > 25 meters
        bool needsRecalc = false;
        if (tState.lastRouteOrigin == null || tState.lastRouteTarget == null) {
          needsRecalc = true;
        } else {
          final distFromOrigin = HaversineCalculator.distanceBetweenMeters(
            tState.lastRouteOrigin!.latitude,
            tState.lastRouteOrigin!.longitude,
            next.myLatLng!.latitude,
            next.myLatLng!.longitude,
          );
          final distFromTarget = HaversineCalculator.distanceBetweenMeters(
            tState.lastRouteTarget!.latitude,
            tState.lastRouteTarget!.longitude,
            targetLatLng.latitude,
            targetLatLng.longitude,
          );
          if (distFromOrigin > 25 || distFromTarget > 25) {
            needsRecalc = true;
          }
        }

        if (needsRecalc && !tState.isLoadingRoute) {
          ref.read(tracingNotifierProvider.notifier).fetchRoadRoute(from: next.myLatLng!, to: targetLatLng);
        }
      }
    });

    // Default center: User position or Manila/Default coords if waiting
    final defaultLatLng = mapState.myLatLng ?? const LatLng(14.5547, 121.0244);

    return Scaffold(
      body: Stack(
        children: [
          // 1. OpenStreetMap Tile Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: defaultLatLng,
              initialZoom: _currentZoom,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: AppConfig.osmTileUrl,
                userAgentPackageName: AppConfig.userAgentPackageName,
              ),

              // 2. Tracing Road Polyline between User and Target Member
              if (tracingState.isTracing && mapState.myLatLng != null && tracingState.tracedMember != null)
                PolylineLayer(
                  polylines: [
                    // Outer road glow / shadow
                    Polyline(
                      points: tracingState.currentRoute != null && tracingState.currentRoute!.points.isNotEmpty
                          ? tracingState.currentRoute!.points
                          : [
                              mapState.myLatLng!,
                              LatLng(tracingState.tracedMember!.latitude, tracingState.tracedMember!.longitude),
                            ],
                      strokeWidth: 8.0,
                      color: AppColors.brandSky.withValues(alpha: 0.35),
                    ),
                    // Core road navigation line
                    Polyline(
                      points: tracingState.currentRoute != null && tracingState.currentRoute!.points.isNotEmpty
                          ? tracingState.currentRoute!.points
                          : [
                              mapState.myLatLng!,
                              LatLng(tracingState.tracedMember!.latitude, tracingState.tracedMember!.longitude),
                            ],
                      strokeWidth: 4.5,
                      color: AppColors.brandSky,
                    ),
                  ],
                ),

              // 3. Member Markers Layer
              MarkerLayer(
                markers: [
                  // Self marker
                  if (mapState.myLatLng != null)
                    Marker(
                      point: mapState.myLatLng!,
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      child: _buildSelfMarker(
                        sharingStatus,
                        selfAlert,
                        (tracingState.isTracing && tracingState.tracedMember != null)
                            ? HaversineCalculator.calculateBearing(
                                mapState.myLatLng!.latitude,
                                mapState.myLatLng!.longitude,
                                tracingState.tracedMember!.latitude,
                                tracingState.tracedMember!.longitude,
                              )
                            : null,
                        tracingState.isNavigationFollowMode,
                      ),
                    ),

                  // Room Member Markers (Only active members with valid coordinates)
                  ...mapState.memberLocations.where((m) => m.hasValidCoordinates).map((member) {
                    final isSelected = mapState.selectedMember?.userId == member.userId ||
                        tracingState.tracedMember?.userId == member.userId;
                    final memberAlert = alertState.activeAlerts
                        .where((a) => a.senderId == member.userId && a.isActive)
                        .firstOrNull;

                    return Marker(
                      point: LatLng(member.latitude, member.longitude),
                      width: 96,
                      height: 96,
                      alignment: Alignment.center,
                      child: MemberMarkerWidget(
                        member: member,
                        isSelected: isSelected,
                        alert: memberAlert,
                        onTap: () => _handleMemberTap(member, mapState),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          ValueListenableBuilder<bool>(
            valueListenable: PipService.instance.isPipMode,
            builder: (context, isPip, _) {
              if (isPip) {
                // In PiP mode: render Google Maps-style navigation HUD
                return _buildPipGoogleMapsHud(mapState);
              }

              return Stack(
                children: [
                  // 4. Top Header: Room Selector & Sleek Compact Sharing Pill (Properly positioned & responsive)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                        child: Row(
                          children: [
                            // Active Room Pill (Tappable to switch / view circles)
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: () => _showRoomSelectorModal(context, roomState),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandNavy.withValues(alpha: 0.94),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.groups_rounded, size: 18, color: AppColors.brandSky),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            currentRoom != null ? currentRoom.name : 'Select Group',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (currentRoom != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.brandSky.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              currentRoom.code,
                                              style: const TextStyle(
                                                color: AppColors.brandSky,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 18,
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Compact Live Sharing Pill (Opens sharing sheet on tap)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => _showSharingOptions(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandNavy.withValues(alpha: 0.94),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: sharingStatus == 'on'
                                          ? AppColors.statusOnline
                                          : (sharingStatus == 'paused' ? AppColors.alertWarning : AppColors.alertEmergency),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: sharingStatus == 'on'
                                              ? AppColors.statusOnline
                                              : (sharingStatus == 'paused' ? AppColors.alertWarning : AppColors.alertEmergency),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        sharingStatus.toUpperCase(),
                                        style: TextStyle(
                                          color: sharingStatus == 'on'
                                              ? AppColors.statusOnline
                                              : (sharingStatus == 'paused' ? AppColors.alertWarning : AppColors.alertEmergency),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 5. Floating Map Controls (Zoom / Recenter / Navigation Follow / PiP)
                Positioned(
                  right: 16,
                  bottom: tracingState.isTracing ? 275 : 24,
                  child: MapControlsWidget(
                    onPip: () => PipService.instance.enterPip(),
                    onToggleNavigationFollow: tracingState.isTracing
                        ? () {
                            ref.read(tracingNotifierProvider.notifier).toggleNavigationFollowMode();
                            final nextMode = !tracingState.isNavigationFollowMode;
                            if (nextMode && mapState.myLatLng != null) {
                              _mapController.move(mapState.myLatLng!, 17.5);
                            } else if (!nextMode && mapState.myLatLng != null && tracingState.tracedMember != null) {
                              _fitTraceBounds(
                                mapState.myLatLng!,
                                LatLng(tracingState.tracedMember!.latitude, tracingState.tracedMember!.longitude),
                              );
                            }
                          }
                        : null,
                    isNavigationFollowActive: tracingState.isNavigationFollowMode,
                    onRecenter: () {
                      if (mapState.myLatLng != null) {
                        _mapController.move(mapState.myLatLng!, _currentZoom);
                      }
                    },
                    onZoomIn: () {
                      setState(() => _currentZoom = (_currentZoom + 1).clamp(3.0, 18.0));
                      _mapController.move(_mapController.camera.center, _currentZoom);
                    },
                    onZoomOut: () {
                      setState(() => _currentZoom = (_currentZoom - 1).clamp(3.0, 18.0));
                      _mapController.move(_mapController.camera.center, _currentZoom);
                    },
                  ),
                ),

                // 5b. Floating Realtime Speedometer & Trip Stats (when not in full tracing mode)
                if (!tracingState.isTracing)
                  Positioned(
                    left: 16,
                    bottom: 24,
                    child: _buildFloatingSpeedometer(mapState),
                  ),

                // 6. Active GPS Tracing HUD Card
                if (tracingState.isTracing)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _buildTraceHudCard(mapState, tracingState),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

  Widget _buildSelfMarker(String sharingStatus, [AlertModel? selfAlert, double? bearing, bool isNavFollow = false]) {
    final hasAlert = selfAlert != null && selfAlert.isActive;
    final isOff = sharingStatus == 'off';
    final isPaused = sharingStatus == 'paused';
    final color = hasAlert
        ? const Color(0xFFE53935)
        : (isOff
            ? AppColors.alertEmergency
            : (isPaused ? AppColors.alertWarning : AppColors.brandBlue));

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (hasAlert)
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE53935).withValues(alpha: 0.25),
              border: Border.all(color: const Color(0xFFE53935), width: 1.5),
            ),
          ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
          ),
        ),
        if (isNavFollow && bearing != null)
          Transform.rotate(
            angle: bearing * math.pi / 180,
            child: const Icon(
              Icons.navigation_rounded,
              color: AppColors.brandSky,
              size: 32,
            ),
          )
        else ...[
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: (hasAlert ? Colors.red : Colors.black).withValues(alpha: 0.35),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                hasAlert ? 'SOS' : (isOff ? 'OFF' : (isPaused ? '||' : 'YOU')),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 6.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _handleMemberTap(MemberLocationModel member, MapState mapState) {
    ref.read(mapNotifierProvider.notifier).selectMember(member);

    double? distance;
    if (mapState.myLatLng != null) {
      distance = HaversineCalculator.distanceBetweenMeters(
        mapState.myLatLng!.latitude,
        mapState.myLatLng!.longitude,
        member.latitude,
        member.longitude,
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MemberDetailsBottomSheet(
        member: member,
        distanceMeters: distance,
        onTraceDirections: () {
          Navigator.pop(context);
          _startTracing(member, mapState);
        },
        onSendMessage: () {
          Navigator.pop(context);
          widget.onNavigateToChat?.call();
        },
        onSendAlert: () {
          Navigator.pop(context);
          widget.onNavigateToAlerts?.call();
        },
        onVoiceCall: () async {
          Navigator.pop(context);
          final currentRoom = ref.read(roomsNotifierProvider).currentRoom;
          if (currentRoom != null) {
            final call = await ref.read(callNotifierProvider.notifier).startCall(
              currentRoom.id,
              isVideo: false,
              targetUserId: member.userId,
            );
            if (call != null && mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CallScreen(call: call)),
              );
            }
          }
        },
      ),
    ).whenComplete(() {
      final tMember = ref.read(tracingNotifierProvider).tracedMember;
      if (tMember?.userId != member.userId) {
        ref.read(mapNotifierProvider.notifier).selectMember(null);
      }
    });
  }

  void _startTracing(MemberLocationModel member, MapState mapState) {
    ref.read(tracingNotifierProvider.notifier).startTracing(member, mapState.myLatLng);
    ref.read(mapNotifierProvider.notifier).selectMember(member);

    final targetLatLng = LatLng(member.latitude, member.longitude);
    if (mapState.myLatLng != null) {
      _fitTraceBounds(mapState.myLatLng!, targetLatLng);
    } else {
      _mapController.move(targetLatLng, 15.0);
    }
  }

  Widget _buildPipGoogleMapsHud(MapState mapState) {
    final tracingState = ref.watch(tracingNotifierProvider);
    final member = tracingState.tracedMember ??
        mapState.selectedMember ??
        (mapState.memberLocations.where((m) => m.hasValidCoordinates).firstOrNull);

    final mySpeedKmh = mapState.currentSpeedKmh.round();
    final topSpeedKmh = mapState.topSpeedKmh.round();
    final avgSpeedKmh = mapState.averageSpeedKmh.round();

    double? distanceMeters;
    if (member != null && mapState.myLatLng != null) {
      distanceMeters = HaversineCalculator.distanceBetweenMeters(
        mapState.myLatLng!.latitude,
        mapState.myLatLng!.longitude,
        member.latitude,
        member.longitude,
      );
    }
    final distStr = distanceMeters != null ? HaversineCalculator.formatDistance(distanceMeters) : '';
    final step = tracingState.currentRoute?.currentStep;

    // Auto-fetch road route if a group member exists and route is not yet fetched
    if (member != null && tracingState.currentRoute == null && mapState.myLatLng != null && !tracingState.isLoadingRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(tracingNotifierProvider).currentRoute == null && mapState.myLatLng != null) {
          ref.read(tracingNotifierProvider.notifier).fetchRoadRoute(
            from: mapState.myLatLng!,
            to: LatLng(member.latitude, member.longitude),
          );
        }
      });
    }

    return Stack(
      children: [
        // 1. Google Maps Navigation Green Banner at Top
        Positioned(
          top: 6,
          left: 6,
          right: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F5132), Color(0xFF198754)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF34D399), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    step?.maneuverIcon ?? Icons.navigation_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        step != null
                            ? 'In ${HaversineCalculator.formatDistance(step.distanceMeters)}'
                            : (member != null ? member.displayName : 'Navigation Active'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        step?.instruction ??
                            (member != null ? 'Tracking $distStr away' : 'Speed $mySpeedKmh km/h'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Google Maps Telemetry Strip at Bottom (Speed + Top/Avg + Distance + ETA)
        Positioned(
          bottom: 6,
          left: 6,
          right: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0B132B).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 6,
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Live Speedometer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.statusOnline.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.statusOnline.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.speed_rounded, size: 11, color: AppColors.statusOnline),
                        const SizedBox(width: 3),
                        Text(
                          '$mySpeedKmh km/h',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  // Top & Avg Speed Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'TOP $topSpeedKmh • AVG $avgSpeedKmh',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (distStr.isNotEmpty || tracingState.currentRoute != null) ...[
                    const SizedBox(width: 5),
                    // Distance & ETA
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tracingState.currentRoute != null ? tracingState.currentRoute!.formattedDistance : distStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (tracingState.currentRoute != null) ...[
                          const SizedBox(width: 3),
                          Text(
                            '(${tracingState.currentRoute!.formattedDuration})',
                            style: const TextStyle(
                              color: AppColors.brandSky,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _stopTracing() {
    ref.read(tracingNotifierProvider.notifier).stopTracing();
    ref.read(mapNotifierProvider.notifier).selectMember(null);
  }

  void _fitTraceBounds(LatLng pointA, LatLng pointB) {
    final bounds = LatLngBounds.fromPoints([pointA, pointB]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 150),
      ),
    );
  }

  Widget _buildFloatingSpeedometer(MapState mapState) {
    final speed = mapState.currentSpeedKmh.round();
    final topSpeed = mapState.topSpeedKmh.round();
    final avgSpeed = mapState.averageSpeedKmh.round();

    final Color accentColor = speed > 100
        ? AppColors.alertEmergency
        : (speed > 60 ? AppColors.alertWarning : AppColors.statusOnline);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTripStatsBottomSheet(mapState),
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1B35).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular speed dial
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.15),
                  border: Border.all(color: accentColor, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$speed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: speed >= 100 ? 12 : 14,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      'km/h',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up_rounded, size: 11, color: AppColors.brandSky),
                      const SizedBox(width: 3),
                      Text(
                        'TOP $topSpeed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.query_stats_rounded, size: 11, color: Colors.white54),
                      const SizedBox(width: 3),
                      Text(
                        'AVG $avgSpeed',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTripStatsBottomSheet(MapState mapState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1B35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final movingMins = (mapState.movingSeconds / 60).floor();
        final movingSecs = mapState.movingSeconds % 60;
        final movingTimeStr = movingMins > 0 ? '${movingMins}m ${movingSecs}s' : '${movingSecs}s';
        final distStr = HaversineCalculator.formatDistance(mapState.totalDistanceMeters);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.speed_rounded, color: AppColors.statusOnline, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Live Speed & Trip Stats',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      ref.read(mapNotifierProvider.notifier).resetSpeedStats();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Trip speed statistics reset.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.brandSky),
                    label: const Text('Reset', style: TextStyle(color: AppColors.brandSky, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // 4 Stat Cards Grid
              Row(
                children: [
                  _buildTripStatCard(
                    title: 'CURRENT SPEED',
                    value: '${mapState.currentSpeedKmh.round()} km/h',
                    icon: Icons.speed_rounded,
                    color: AppColors.statusOnline,
                  ),
                  const SizedBox(width: 10),
                  _buildTripStatCard(
                    title: 'TOP SPEED',
                    value: '${mapState.topSpeedKmh.round()} km/h',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.alertWarning,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildTripStatCard(
                    title: 'AVERAGE SPEED',
                    value: '${mapState.averageSpeedKmh.round()} km/h',
                    icon: Icons.query_stats_rounded,
                    color: AppColors.brandSky,
                  ),
                  const SizedBox(width: 10),
                  _buildTripStatCard(
                    title: 'TRIP DISTANCE',
                    value: distStr,
                    icon: Icons.route_rounded,
                    color: const Color(0xFF38BDF8),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Moving time: $movingTimeStr • Continuous GPS stream active',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTripStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraceHudCard(MapState mapState, TracingState tracingState) {
    final member = tracingState.tracedMember;
    if (member == null) return const SizedBox.shrink();

    double? distanceMeters;
    double? bearing;
    String cardinal = '';
    String travelTime = '';

    if (mapState.myLatLng != null) {
      distanceMeters = HaversineCalculator.distanceBetweenMeters(
        mapState.myLatLng!.latitude,
        mapState.myLatLng!.longitude,
        member.latitude,
        member.longitude,
      );
      bearing = HaversineCalculator.calculateBearing(
        mapState.myLatLng!.latitude,
        mapState.myLatLng!.longitude,
        member.latitude,
        member.longitude,
      );
      cardinal = HaversineCalculator.headingToCardinal(bearing);
      travelTime = HaversineCalculator.estimateTravelTime(distanceMeters);
    }

    // Live speeds in km/h
    final mySpeedKmh = mapState.currentSpeedKmh.round();
    final topSpeedKmh = mapState.topSpeedKmh.round();
    final avgSpeedKmh = mapState.averageSpeedKmh.round();
    final targetSpeedKmh = (member.speed != null && member.speed! >= 0)
        ? member.speed!.round()
        : 0;

    final currentStep = tracingState.currentRoute?.currentStep;
    final currentRoute = tracingState.currentRoute;
    final isSoundEnabled = tracingState.isSoundEnabled;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brandNavy.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.brandSky.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Member info, sound toggle, close button
          Row(
            children: [
              MarLinkAvatar(
                imageUrl: member.avatarUrl,
                name: member.displayName,
                radius: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.brandSky.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ROAD GPS',
                            style: TextStyle(
                              color: AppColors.brandSky,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentRoute != null
                          ? '${currentRoute.formattedDistance} on road • ETA ${currentRoute.formattedDuration}${cardinal.isNotEmpty ? ' • $cardinal' : ''}'
                          : (distanceMeters != null
                              ? '${HaversineCalculator.formatDistance(distanceMeters)}${travelTime.isNotEmpty ? ' ($travelTime)' : ''}${cardinal.isNotEmpty ? ' • $cardinal' : ''}'
                              : 'Calculating route...'),
                      style: const TextStyle(
                        color: AppColors.brandSky,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Sound / Audio Chime toggle button
              IconButton(
                icon: Icon(
                  isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: isSoundEnabled ? AppColors.brandSky : Colors.white38,
                  size: 22,
                ),
                tooltip: isSoundEnabled ? 'Audio Alert On' : 'Audio Alert Muted',
                onPressed: () {
                  ref.read(tracingNotifierProvider.notifier).toggleSound();
                  if (!isSoundEnabled) {
                    NotificationService.instance.playChime();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                tooltip: 'Stop Tracing',
                onPressed: _stopTracing,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Turn-by-Turn Maneuver Banner (like Google Maps)
          if (currentStep != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.brandSky.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: AppColors.brandSky,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      currentStep.maneuverIcon,
                      color: AppColors.brandNavy,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      currentStep.instruction,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ] else if (tracingState.isLoadingRoute) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandSky),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Finding best road route...',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 8),

          // Real-time Speeds and Telemetry Row
          Row(
            children: [
              // User Speed & Stats
              Expanded(
                child: InkWell(
                  onTap: () => _showTripStatsBottomSheet(mapState),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.speed_rounded, color: AppColors.statusOnline, size: 16),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'MY SPEED',
                                    style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'TOP $topSpeedKmh • AVG $avgSpeedKmh',
                                    style: const TextStyle(color: AppColors.brandSky, fontSize: 8.5, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              Text(
                                '$mySpeedKmh km/h',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Target Member Speed
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_run_rounded, color: AppColors.brandSky, size: 16),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.displayName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '$targetSpeedKmh km/h',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Action Buttons: Wide Overview, Realtime Follow Navigation, Focus Target
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (mapState.myLatLng != null) {
                      ref.read(tracingNotifierProvider.notifier).setNavigationFollowMode(false);
                      _fitTraceBounds(
                        mapState.myLatLng!,
                        LatLng(member.latitude, member.longitude),
                      );
                    }
                  },
                  icon: const Icon(Icons.crop_free, size: 15),
                  label: const Text('Wide', style: TextStyle(fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(tracingNotifierProvider.notifier).toggleNavigationFollowMode();
                    final nextMode = !tracingState.isNavigationFollowMode;
                    if (nextMode && mapState.myLatLng != null) {
                      _mapController.move(mapState.myLatLng!, 17.5);
                    }
                  },
                  icon: Icon(
                    tracingState.isNavigationFollowMode ? Icons.navigation_rounded : Icons.explore_outlined,
                    size: 15,
                  ),
                  label: Text(
                    tracingState.isNavigationFollowMode ? 'Following' : 'Follow',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tracingState.isNavigationFollowMode
                        ? AppColors.statusOnline
                        : AppColors.brandBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(tracingNotifierProvider.notifier).setNavigationFollowMode(false);
                    _mapController.move(LatLng(member.latitude, member.longitude), 16.0);
                  },
                  icon: const Icon(Icons.person_pin_circle_outlined, size: 15),
                  label: const Text('Target', style: TextStyle(fontSize: 11.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandSky,
                    foregroundColor: AppColors.brandNavy,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSharingOptions(BuildContext context) {
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
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Location Sharing Privacy Controls',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.sensors, color: AppColors.statusOnline),
                title: const Text('Share Live Location (🟢 ON)'),
                subtitle: const Text('Stream updates to active group members'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(mapNotifierProvider.notifier).captureCurrentPosition(openSettingsIfDisabled: true);
                  ref.read(mapNotifierProvider.notifier).setBroadcasting(true);
                  await ref.read(authNotifierProvider.notifier).updateLocationSharing(status: 'on');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🟢 Live location sharing is ON'),
                        backgroundColor: AppColors.statusOnline,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: AppColors.brandBlue),
                title: const Text('Share for 1 Hour'),
                subtitle: const Text('Automatically pause after 60 minutes'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(mapNotifierProvider.notifier).captureCurrentPosition(openSettingsIfDisabled: true);
                  ref.read(mapNotifierProvider.notifier).setBroadcasting(true);
                  await ref.read(authNotifierProvider.notifier).updateLocationSharing(status: 'on');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⏳ Live location sharing set for 1 hour'),
                        backgroundColor: AppColors.brandBlue,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.pause_circle_outline, color: AppColors.alertWarning),
                title: const Text('Pause Sharing (🟡 PAUSED)'),
                subtitle: const Text('Keep last known location, freeze live stream'),
                onTap: () async {
                  Navigator.pop(ctx);
                  ref.read(mapNotifierProvider.notifier).setBroadcasting(false);
                  await ref.read(authNotifierProvider.notifier).updateLocationSharing(status: 'paused');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🟡 Live location sharing is PAUSED'),
                        backgroundColor: AppColors.alertWarning,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_off_outlined, color: AppColors.alertEmergency),
                title: const Text('Turn Off Location (🔴 OFF)'),
                subtitle: const Text('Completely stop location broadcasting'),
                onTap: () async {
                  Navigator.pop(ctx);
                  ref.read(mapNotifierProvider.notifier).setBroadcasting(false);
                  await ref.read(authNotifierProvider.notifier).updateLocationSharing(status: 'off');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔴 Location sharing is OFF. Group members cannot see your location.'),
                        backgroundColor: AppColors.alertEmergency,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRoomSelectorModal(BuildContext context, RoomsState roomState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentRoom = roomState.currentRoom;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.groups_rounded, color: AppColors.brandSky, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Switch Active Group',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a group to view member positions and broadcast updates.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                if (roomState.rooms.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No groups yet. Create or join one below.',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.35,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: roomState.rooms.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final room = roomState.rooms[idx];
                        final isSelected = room.id == currentRoom?.id;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? AppColors.brandSky.withValues(alpha: 0.2)
                                : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
                            child: Icon(
                              Icons.groups_rounded,
                              color: isSelected ? AppColors.brandSky : Colors.grey,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            room.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.brandSky : null,
                            ),
                          ),
                          subtitle: Text(
                            'Code: ${room.code} • ${room.membersCount} member${room.membersCount == 1 ? '' : 's'}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.brandSky, size: 22)
                              : null,
                          onTap: () {
                            if (ref.read(tracingNotifierProvider).isTracing) {
                              ref.read(tracingNotifierProvider.notifier).stopTracing();
                            }
                            ref.read(roomsNotifierProvider.notifier).selectRoom(room);
                            ref.read(mapNotifierProvider.notifier).clearRoomLocations();
                            ref.read(mapNotifierProvider.notifier).fetchRoomLocations();
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create Group'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          showDialog(
                            context: context,
                            builder: (_) => const CreateRoomDialog(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.group_add, size: 18),
                        label: const Text('Join Group'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandNavy,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          showDialog(
                            context: context,
                            builder: (_) => const JoinRoomDialog(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
