class MessageAttachmentModel {
  final int id;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String mimeType;

  MessageAttachmentModel({
    required this.id,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
  });

  factory MessageAttachmentModel.fromJson(Map<String, dynamic> json) {
    return MessageAttachmentModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      fileUrl: json['file_url'] ?? '',
      fileName: json['file_name'] ?? '',
      fileSize: json['file_size'] is int ? json['file_size'] : int.parse(json['file_size'].toString()),
      mimeType: json['mime_type'] ?? '',
    );
  }
}

class MessageModel {
  final int id;
  final int roomId;
  final int userId;
  final String senderName;
  final String? senderAvatar;
  final String messageType; // 'text', 'image', 'location'
  final String? content;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;
  final List<MessageAttachmentModel> attachments;
  final bool isDeleted;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.senderName,
    this.senderAvatar,
    required this.messageType,
    this.content,
    this.latitude,
    this.longitude,
    this.locationLabel,
    this.attachments = const [],
    this.isDeleted = false,
    required this.createdAt,
  });

  bool get isLocation => messageType == 'location';
  bool get isImage => messageType == 'image';
  bool get isCallLog => messageType == 'call_log';

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    final loc = json['location'] as Map<String, dynamic>?;

    var attList = <MessageAttachmentModel>[];
    if (json['attachments'] is List) {
      attList = (json['attachments'] as List)
          .map((a) => MessageAttachmentModel.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    final lat = loc != null
        ? (loc['latitude'] as num?)?.toDouble()
        : (json['latitude'] != null ? (json['latitude'] as num).toDouble() : null);
    final lng = loc != null
        ? (loc['longitude'] as num?)?.toDouble()
        : (json['longitude'] != null ? (json['longitude'] as num).toDouble() : null);
    final lbl = loc != null
        ? loc['label']?.toString()
        : (json['location_label']?.toString() ?? 'Shared Location');

    return MessageModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      roomId: json['room_id'] is int ? json['room_id'] : int.parse(json['room_id'].toString()),
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      senderName: sender?['name'] ?? (json['sender_name'] ?? 'User'),
      senderAvatar: sender?['avatar_url'] ?? json['sender_avatar'],
      messageType: json['message_type'] ?? 'text',
      content: json['content'],
      latitude: lat,
      longitude: lng,
      locationLabel: lbl,
      attachments: attList,
      isDeleted: json['is_deleted'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
