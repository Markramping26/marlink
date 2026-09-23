import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../domain/models/call_model.dart';

class CallRepository {
  final ApiClient _apiClient;

  CallRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<CallModel> initiateCall(int roomId, {required String callType, int? targetUserId}) async {
    final Map<String, dynamic> payload = {'call_type': callType};
    if (targetUserId != null && targetUserId > 0) {
      payload['target_user_id'] = targetUserId;
    }
    final response = await _apiClient.post(
      ApiEndpoints.roomCalls(roomId),
      data: payload,
      fromJsonT: (data) => CallModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<CallModel?> getActiveCall() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.activeCall,
        fromJsonT: (data) {
          if (data == null || data is! Map<String, dynamic>) return null;
          return CallModel.fromJson(data);
        },
      );
      return response.data;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<CallModel?> getCallDetails(int callId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.callDetails(callId),
        fromJsonT: (data) => CallModel.fromJson(data as Map<String, dynamic>),
      );
      return response.data;
    } catch (_) {
      return null;
    }
  }

  Future<CallModel?> joinCall(int callId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.callJoin(callId),
        fromJsonT: (data) => CallModel.fromJson(data as Map<String, dynamic>),
      );
      return response.data;
    } catch (_) {
      return null;
    }
  }

  Future<bool> declineCall(int callId) async {
    try {
      await _apiClient.post(ApiEndpoints.callDecline(callId));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> endCall(int callId) async {
    try {
      await _apiClient.post(ApiEndpoints.callEnd(callId));
      return true;
    } catch (_) {
      return false;
    }
  }
}
