class MemberLocationModel {
  final int userId;
  final String name;
  final String username;
  final String? customNickname;
  final String? avatarUrl;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final int? batteryPct;
  final bool isMoving;
  final String sharingStatus;
  final bool isSharingActive;
  final DateTime recordedAt;

  MemberLocationModel({
    required this.userId,
    required this.name,
    required this.username,
    this.customNickname,
    this.avatarUrl,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    this.batteryPct,
    this.isMoving = false,
    this.sharingStatus = 'on',
    this.isSharingActive = true,
    required this.recordedAt,
  });

  String get displayName => customNickname ?? name;

  bool get hasValidCoordinates =>
      latitude != 0.0 && longitude != 0.0 && isSharingActive && sharingStatus == 'on';

  factory MemberLocationModel.fromJson(Map<String, dynamic> json) {
    final rawLat = json['latitude'];
    final rawLng = json['longitude'];
    final lat = rawLat != null ? (rawLat as num).toDouble() : 0.0;
    final lng = rawLng != null ? (rawLng as num).toDouble() : 0.0;
    final status = (json['sharing_status'] as String?) ?? 'on';
    final active = (json['is_sharing_active'] as bool?) ?? (status == 'on');

    return MemberLocationModel(
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      customNickname: json['custom_nickname'],
      avatarUrl: json['avatar_url'],
      latitude: lat,
      longitude: lng,
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      heading: json['heading'] != null ? (json['heading'] as num).toDouble() : null,
      batteryPct: json['battery_pct'],
      isMoving: json['is_moving'] ?? false,
      sharingStatus: status,
      isSharingActive: active,
      recordedAt: DateTime.tryParse(json['recorded_at'] ?? '') ?? DateTime.now(),
    );
  }
}
