import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../domain/models/message_model.dart';

class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<MessageModel>> getMessages(int roomId, {int page = 1}) async {
    final response = await _apiClient.get(
      ApiEndpoints.roomMessages(roomId),
      queryParameters: {'page': page, 'per_page': 40},
      fromJsonT: (data) {
        if (data is List) {
          return data.map((m) => MessageModel.fromJson(m as Map<String, dynamic>)).toList();
        }
        if (data is Map<String, dynamic>) {
          final list = (data['messages'] ?? data['data'] ?? []) as List;
          return list.map((m) => MessageModel.fromJson(m as Map<String, dynamic>)).toList();
        }
        return <MessageModel>[];
      },
    );
    return response.data ?? [];
  }

  Future<MessageModel> sendTextMessage(int roomId, String content, {int? replyToId}) async {
    final response = await _apiClient.post(
      ApiEndpoints.roomMessages(roomId),
      data: {
        'message_type': 'text',
        'content': content,
        if (replyToId != null) 'reply_to_id': replyToId,
      },
      fromJsonT: (data) => MessageModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<MessageModel> sendLocationMessage(
    int roomId, {
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.roomMessages(roomId),
      data: {
        'message_type': 'location',
        'latitude': latitude,
        'longitude': longitude,
        'location_label': label ?? 'Pinned Location',
      },
      fromJsonT: (data) => MessageModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<MessageModel> sendImageMessage(int roomId, File file, {String? caption}) async {
    final fileName = file.path.split(RegExp(r'[/\\]')).last;
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(file.path, filename: fileName),
      if (caption != null) 'caption': caption,
    });

    final response = await _apiClient.post(
      ApiEndpoints.roomUploadMedia(roomId),
      data: formData,
      fromJsonT: (data) => MessageModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<void> deleteMessage(int roomId, int messageId) async {
    await _apiClient.delete('${ApiEndpoints.roomMessages(roomId)}/$messageId');
  }
}
