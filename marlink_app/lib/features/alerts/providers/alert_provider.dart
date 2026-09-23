import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../rooms/providers/room_provider.dart';
import '../data/alert_repository.dart';
import '../domain/models/alert_model.dart';

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository();
});

class AlertState {
  final List<AlertModel> activeAlerts;
  final bool isDispatching;
  final String? errorMessage;

  const AlertState({
    this.activeAlerts = const [],
    this.isDispatching = false,
    this.errorMessage,
  });

  AlertState copyWith({
    List<AlertModel>? activeAlerts,
    bool? isDispatching,
    String? errorMessage,
  }) {
    return AlertState(
      activeAlerts: activeAlerts ?? this.activeAlerts,
      isDispatching: isDispatching ?? this.isDispatching,
      errorMessage: errorMessage,
    );
  }
}

final alertNotifierProvider = StateNotifierProvider<AlertNotifier, AlertState>((ref) {
  final repository = ref.watch(alertRepositoryProvider);
  return AlertNotifier(repository, ref);
});

class AlertNotifier extends StateNotifier<AlertState> {
  final AlertRepository _repository;
  final Ref _ref;

  AlertNotifier(this._repository, this._ref) : super(const AlertState());

  Future<bool> sendAttention({
    int? targetUserId,
    required String alertType,
    String? message,
    double? latitude,
    double? longitude,
  }) async {
    final currentRoom = _ref.read(roomsNotifierProvider).currentRoom;
    if (currentRoom == null) return false;

    state = state.copyWith(isDispatching: true, errorMessage: null);
    try {
      final alert = await _repository.sendAttentionAlert(
        roomId: currentRoom.id,
        targetUserId: targetUserId,
        alertType: alertType,
        message: message,
        latitude: latitude,
        longitude: longitude,
      );
      state = state.copyWith(
        isDispatching: false,
        activeAlerts: [alert, ...state.activeAlerts],
      );

      NotificationService.instance.showNotification(
        title: '🚨 MarLink Safety Alert',
        body: message ?? 'Safety attention alert sent to "${currentRoom.name}"',
        isAlert: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isDispatching: false,
        errorMessage: 'Unable to send alert. Rate limit cooldown is 30s.',
      );
      return false;
    }
  }

  Future<bool> triggerSos({
    required double latitude,
    required double longitude,
    double? speed,
    int? batteryPct,
    String? note,
  }) async {
    final currentRoom = _ref.read(roomsNotifierProvider).currentRoom;
    if (currentRoom == null) return false;

    state = state.copyWith(isDispatching: true, errorMessage: null);
    try {
      final alert = await _repository.triggerSos(
        roomId: currentRoom.id,
        latitude: latitude,
        longitude: longitude,
        speed: speed,
        batteryPct: batteryPct,
        emergencyNote: note,
      );
      state = state.copyWith(
        isDispatching: false,
        activeAlerts: [alert, ...state.activeAlerts],
      );

      NotificationService.instance.showSosAlert(
        senderName: 'You (Emergency SOS)',
        roomName: currentRoom.name,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isDispatching: false, errorMessage: 'Failed to activate SOS alert.');
      return false;
    }
  }

  Future<void> acknowledgeAlert(int alertId) async {
    final currentRoom = _ref.read(roomsNotifierProvider).currentRoom;
    if (currentRoom == null) return;

    try {
      final updated = await _repository.acknowledgeAlert(currentRoom.id, alertId);
      final list = state.activeAlerts.map((a) => a.id == alertId ? updated : a).toList();
      state = state.copyWith(activeAlerts: list);
    } catch (_) {}
  }

  Future<void> cancelSos(int alertId) async {
    final currentRoom = _ref.read(roomsNotifierProvider).currentRoom;
    if (currentRoom == null) return;

    try {
      final updated = await _repository.cancelSos(currentRoom.id, alertId);
      final list = state.activeAlerts.map((a) => a.id == alertId ? updated : a).toList();
      state = state.copyWith(activeAlerts: list);
    } catch (_) {}
  }
}
