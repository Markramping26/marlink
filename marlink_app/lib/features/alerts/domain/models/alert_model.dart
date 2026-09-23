class AlertModel {
  final int id;
  final int roomId;
  final String alertType; // 'attention', 'meet_here', 'leaving', 'arrived', 'check_on_me', 'sos'
  final String status; // 'active', 'acknowledged', 'cancelled'
  final bool isSos;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final int? targetUserId;
  final String? targetUserName;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? metadata;
  final DateTime? acknowledgedAt;
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.roomId,
    required this.alertType,
    required this.status,
    required this.isSos,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.targetUserId,
    this.targetUserName,
    this.latitude,
    this.longitude,
    this.metadata,
    this.acknowledgedAt,
    required this.createdAt,
  });

  bool get isActive => status == 'active';

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    final target = json['target_user'] as Map<String, dynamic>?;

    return AlertModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      roomId: json['room_id'] is int ? json['room_id'] : int.parse(json['room_id'].toString()),
      alertType: json['alert_type'] ?? 'attention',
      status: json['status'] ?? 'active',
      isSos: json['is_sos'] ?? false,
      senderId: sender?['id'] is int ? sender!['id'] : 0,
      senderName: sender?['name'] ?? 'Member',
      senderAvatar: sender?['avatar_url'],
      targetUserId: target?['id'] is int ? target!['id'] : null,
      targetUserName: target?['name'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] : null,
      acknowledgedAt: json['acknowledged_at'] != null ? DateTime.tryParse(json['acknowledged_at']) : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
