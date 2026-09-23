import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../domain/models/alert_model.dart';

class AlertRepository {
  final ApiClient _apiClient;

  AlertRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<AlertModel> sendAttentionAlert({
    required int roomId,
    int? targetUserId,
    required String alertType,
    String? message,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.roomAlerts(roomId),
      data: {
        'target_user_id': targetUserId,
        'alert_type': alertType,
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
      },
      fromJsonT: (data) => AlertModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<AlertModel> triggerSos({
    required int roomId,
    required double latitude,
    required double longitude,
    double? speed,
    int? batteryPct,
    String? emergencyNote,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.roomSos(roomId),
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'battery_pct': batteryPct,
        'emergency_note': emergencyNote,
      },
      fromJsonT: (data) => AlertModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<AlertModel> acknowledgeAlert(int roomId, int alertId) async {
    final response = await _apiClient.post(
      ApiEndpoints.alertAcknowledge(roomId, alertId),
      fromJsonT: (data) => AlertModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<AlertModel> cancelSos(int roomId, int alertId) async {
    final response = await _apiClient.post(
      ApiEndpoints.alertCancel(roomId, alertId),
      fromJsonT: (data) => AlertModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }
}
