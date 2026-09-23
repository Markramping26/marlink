import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../domain/models/room_model.dart';

class RoomRepository {
  final ApiClient _apiClient;

  RoomRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<RoomModel>> getRooms() async {
    final response = await _apiClient.get(
      ApiEndpoints.rooms,
      fromJsonT: (data) {
        if (data is List) {
          return data.map((json) => RoomModel.fromJson(json as Map<String, dynamic>)).toList();
        }
        return <RoomModel>[];
      },
    );
    return response.data ?? [];
  }

  Future<RoomModel> createRoom({
    required String name,
    String? description,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.rooms,
      data: {
        'name': name,
        'description': description,
      },
      fromJsonT: (data) => RoomModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<RoomModel> joinRoom({
    required String code,
    String? customNickname,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.joinRoom,
      data: {
        'code': code.trim().toUpperCase(),
        'custom_nickname': customNickname,
      },
      fromJsonT: (data) => RoomModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<RoomModel> getRoomDetails(int roomId) async {
    final response = await _apiClient.get(
      ApiEndpoints.roomDetails(roomId),
      fromJsonT: (data) => RoomModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<void> leaveRoom(int roomId) async {
    await _apiClient.post(ApiEndpoints.roomLeave(roomId));
  }

  Future<void> removeMember(int roomId, int userId) async {
    await _apiClient.delete(ApiEndpoints.roomMemberRemove(roomId, userId));
  }
}
