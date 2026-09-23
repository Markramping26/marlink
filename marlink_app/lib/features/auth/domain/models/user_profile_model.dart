class UserProfileModel {
  final String? avatarUrl;
  final String? bio;
  final int batteryPct;
  final String sharingStatus; // 'on', 'paused', 'off'
  final bool isSharingActive;
  final DateTime? sharingExpiresAt;
  final bool showSpeed;
  final bool showBattery;
  final bool allowGeofenceAlerts;
  final DateTime? lastSeenAt;

  UserProfileModel({
    this.avatarUrl,
    this.bio,
    this.batteryPct = 100,
    this.sharingStatus = 'on',
    this.isSharingActive = true,
    this.sharingExpiresAt,
    this.showSpeed = true,
    this.showBattery = true,
    this.allowGeofenceAlerts = true,
    this.lastSeenAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      batteryPct: json['battery_pct'] ?? 100,
      sharingStatus: json['sharing_status'] ?? 'on',
      isSharingActive: json['is_sharing_active'] ?? true,
      sharingExpiresAt: json['sharing_expires_at'] != null
          ? DateTime.tryParse(json['sharing_expires_at'])
          : null,
      showSpeed: json['show_speed'] ?? true,
      showBattery: json['show_battery'] ?? true,
      allowGeofenceAlerts: json['allow_geofence_alerts'] ?? true,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'avatar_url': avatarUrl,
        'bio': bio,
        'battery_pct': batteryPct,
        'sharing_status': sharingStatus,
        'is_sharing_active': isSharingActive,
        'sharing_expires_at': sharingExpiresAt?.toIso8601String(),
        'show_speed': showSpeed,
        'show_battery': showBattery,
        'allow_geofence_alerts': allowGeofenceAlerts,
        'last_seen_at': lastSeenAt?.toIso8601String(),
      };

  UserProfileModel copyWith({
    String? avatarUrl,
    String? bio,
    int? batteryPct,
    String? sharingStatus,
    bool? isSharingActive,
    DateTime? sharingExpiresAt,
    bool? showSpeed,
    bool? showBattery,
    bool? allowGeofenceAlerts,
    DateTime? lastSeenAt,
  }) {
    return UserProfileModel(
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      batteryPct: batteryPct ?? this.batteryPct,
      sharingStatus: sharingStatus ?? this.sharingStatus,
      isSharingActive: isSharingActive ?? this.isSharingActive,
      sharingExpiresAt: sharingExpiresAt ?? this.sharingExpiresAt,
      showSpeed: showSpeed ?? this.showSpeed,
      showBattery: showBattery ?? this.showBattery,
      allowGeofenceAlerts: allowGeofenceAlerts ?? this.allowGeofenceAlerts,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}

