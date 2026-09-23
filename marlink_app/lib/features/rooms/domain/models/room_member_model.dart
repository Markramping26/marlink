class RoomMemberModel {
  final int id;
  final int userId;
  final String name;
  final String username;
  final String? customNickname;
  final String displayName;
  final String? avatarUrl;
  final String role; // 'owner', 'admin', 'member'
  final bool isLocationEnabled;
  final String sharingStatus; // 'on', 'paused', 'off'
  final bool isSharingActive;
  final int? batteryPct;
  final DateTime? lastSeenAt;
  final DateTime? joinedAt;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final bool isMoving;
  final DateTime? recordedAt;

  RoomMemberModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.username,
    this.customNickname,
    required this.displayName,
    this.avatarUrl,
    required this.role,
    required this.isLocationEnabled,
    required this.sharingStatus,
    required this.isSharingActive,
    this.batteryPct,
    this.lastSeenAt,
    this.joinedAt,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    this.isMoving = false,
    this.recordedAt,
  });

  bool get isAdminOrOwner => role == 'owner' || role == 'admin';

  factory RoomMemberModel.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>?;

    return RoomMemberModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      customNickname: json['custom_nickname'],
      displayName: json['display_name'] ?? json['name'] ?? '',
      avatarUrl: json['avatar_url'],
      role: json['role'] ?? 'member',
      isLocationEnabled: json['is_location_enabled'] ?? true,
      sharingStatus: json['sharing_status'] ?? 'off',
      isSharingActive: json['is_sharing_active'] ?? false,
      batteryPct: json['battery_pct'],
      lastSeenAt: json['last_seen_at'] != null ? DateTime.tryParse(json['last_seen_at']) : null,
      joinedAt: json['joined_at'] != null ? DateTime.tryParse(json['joined_at']) : null,
      latitude: loc != null ? (loc['latitude'] as num?)?.toDouble() : null,
      longitude: loc != null ? (loc['longitude'] as num?)?.toDouble() : null,
      accuracy: loc != null ? (loc['accuracy'] as num?)?.toDouble() : null,
      speed: loc != null ? (loc['speed'] as num?)?.toDouble() : null,
      heading: loc != null ? (loc['heading'] as num?)?.toDouble() : null,
      isMoving: loc != null ? (loc['is_moving'] ?? false) : false,
      recordedAt: loc != null && loc['recorded_at'] != null
          ? DateTime.tryParse(loc['recorded_at'])
          : null,
    );
  }
}
