import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../domain/models/member_location_model.dart';

class LocationRepository {
  final ApiClient _apiClient;

  LocationRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<void> sendLocationUpdate({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    int? batteryPct,
    bool isMoving = false,
    bool saveHistory = false,
  }) async {
    await _apiClient.post(
      ApiEndpoints.updateLocation,
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'battery_pct': batteryPct,
        'is_moving': isMoving,
        'save_history': saveHistory,
      },
    );
  }

  Future<List<MemberLocationModel>> getRoomLocations(int roomId) async {
    final response = await _apiClient.get(
      ApiEndpoints.roomLocations(roomId),
      fromJsonT: (data) {
        if (data is List) {
          final list = <MemberLocationModel>[];
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              try {
                final model = MemberLocationModel.fromJson(item);
                if (model.hasValidCoordinates) {
                  list.add(model);
                }
              } catch (_) {}
            }
          }
          return list;
        }
        return <MemberLocationModel>[];
      },
    );
    return response.data ?? [];
  }

  Future<void> clearHistory() async {
    await _apiClient.delete(ApiEndpoints.locationHistory);
  }
}
