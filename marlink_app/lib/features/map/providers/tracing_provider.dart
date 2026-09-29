import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/routing_service.dart';
import '../../../../core/utils/haversine_calculator.dart';
import '../domain/models/member_location_model.dart';

class TracingState {
  final MemberLocationModel? tracedMember;
  final RoadRoute? currentRoute;
  final bool isNavigationFollowMode;
  final bool isLoadingRoute;
  final bool isSoundEnabled;
  final LatLng? lastRouteOrigin;
  final LatLng? lastRouteTarget;
  final String? lastChimeInstruction;

  const TracingState({
    this.tracedMember,
    this.currentRoute,
    this.isNavigationFollowMode = false,
    this.isLoadingRoute = false,
    this.isSoundEnabled = true,
    this.lastRouteOrigin,
    this.lastRouteTarget,
    this.lastChimeInstruction,
  });

  bool get isTracing => tracedMember != null;

  TracingState copyWith({
    MemberLocationModel? tracedMember,
    bool clearTracedMember = false,
    RoadRoute? currentRoute,
    bool clearCurrentRoute = false,
    bool? isNavigationFollowMode,
    bool? isLoadingRoute,
    bool? isSoundEnabled,
    LatLng? lastRouteOrigin,
    LatLng? lastRouteTarget,
    String? lastChimeInstruction,
  }) {
    return TracingState(
      tracedMember: clearTracedMember ? null : (tracedMember ?? this.tracedMember),
      currentRoute: clearCurrentRoute ? null : (currentRoute ?? this.currentRoute),
      isNavigationFollowMode: isNavigationFollowMode ?? this.isNavigationFollowMode,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      lastRouteOrigin: lastRouteOrigin ?? this.lastRouteOrigin,
      lastRouteTarget: lastRouteTarget ?? this.lastRouteTarget,
      lastChimeInstruction: lastChimeInstruction ?? this.lastChimeInstruction,
    );
  }
}

final tracingNotifierProvider =
    StateNotifierProvider<TracingNotifier, TracingState>((ref) {
  return TracingNotifier();
});

class TracingNotifier extends StateNotifier<TracingState> {
  TracingNotifier() : super(const TracingState());

  static const int navigationNotificationId = 7777;

  void startTracing(MemberLocationModel member, LatLng? myLocation) {
    state = state.copyWith(
      tracedMember: member,
      clearCurrentRoute: true,
      isNavigationFollowMode: false,
    );

    if (myLocation != null) {
      final targetLatLng = LatLng(member.latitude, member.longitude);
      fetchRoadRoute(from: myLocation, to: targetLatLng);

      final distanceMeters = HaversineCalculator.distanceBetweenMeters(
        myLocation.latitude,
        myLocation.longitude,
        member.latitude,
        member.longitude,
      );
      final distStr = HaversineCalculator.formatDistance(distanceMeters);
      NotificationService.instance.showNotification(
        id: navigationNotificationId,
        title: '🎯 Tracing ${member.displayName}',
        body: 'Calculating road route • $distStr',
        isAlert: false,
        isNavigation: true,
      );
    }
  }

  void stopTracing() {
    NotificationService.instance.cancelNotification(navigationNotificationId);
    state = const TracingState();
  }

  void toggleNavigationFollowMode() {
    state = state.copyWith(isNavigationFollowMode: !state.isNavigationFollowMode);
  }

  void setNavigationFollowMode(bool follow) {
    state = state.copyWith(isNavigationFollowMode: follow);
  }

  void toggleSound() {
    state = state.copyWith(isSoundEnabled: !state.isSoundEnabled);
  }

  void updateTracedMember(MemberLocationModel updated) {
    if (state.tracedMember?.userId == updated.userId) {
      state = state.copyWith(tracedMember: updated);
    }
  }

  Future<void> fetchRoadRoute({required LatLng from, required LatLng to}) async {
    if (state.isLoadingRoute) return;
    state = state.copyWith(isLoadingRoute: true);

    try {
      final route = await RoutingService.instance.getRoadRoute(from: from, to: to);
      if (state.isTracing) {
        state = state.copyWith(
          currentRoute: route,
          lastRouteOrigin: from,
          lastRouteTarget: to,
          isLoadingRoute: false,
        );

        final step = route?.currentStep;
        if (state.tracedMember != null) {
          final member = state.tracedMember!;
          if (step != null && route != null) {
            final stepDistClean = HaversineCalculator.formatDistance(step.distanceMeters, includeAway: false);
            final emoji = step.maneuverEmoji;
            final roadTitle = step.roadName.isNotEmpty ? step.roadName : step.instruction;

            NotificationService.instance.showNotification(
              id: navigationNotificationId,
              title: '$emoji In $stepDistClean • $roadTitle',
              body: '${step.instruction} • ${route.formattedDistance} (${route.formattedDuration}) to ${member.displayName}',
              isAlert: false,
              isNavigation: true,
            );
          } else if (route != null) {
            NotificationService.instance.showNotification(
              id: navigationNotificationId,
              title: '🎯 Tracing ${member.displayName}',
              body: '${route.formattedDistance} remaining (${route.formattedDuration}) • Road navigation active',
              isAlert: false,
              isNavigation: true,
            );
          }
        }

        if (state.isSoundEnabled &&
            step != null &&
            step.instruction != state.lastChimeInstruction) {
          state = state.copyWith(lastChimeInstruction: step.instruction);
          NotificationService.instance.playChime();
        }
      } else {
        state = state.copyWith(isLoadingRoute: false);
      }
    } catch (_) {
      state = state.copyWith(isLoadingRoute: false);
    }
  }
}
