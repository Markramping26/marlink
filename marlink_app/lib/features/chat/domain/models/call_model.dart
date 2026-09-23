class CallParticipantModel {
  final int id;
  final int userId;
  final String name;
  final String username;
  final String? avatarUrl;
  final String status; // 'ringing', 'joined', 'left', 'declined'
  final DateTime? joinedAt;

  CallParticipantModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.username,
    this.avatarUrl,
    required this.status,
    this.joinedAt,
  });

  bool get isJoined => status == 'joined';
  bool get isRinging => status == 'ringing';
  bool get isDeclined => status == 'declined';
  bool get isLeft => status == 'left';

  factory CallParticipantModel.fromJson(Map<String, dynamic> json) {
    return CallParticipantModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      name: json['name']?.toString() ?? 'Member',
      username: json['username']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      status: json['status']?.toString() ?? 'ringing',
      joinedAt: json['joined_at'] != null ? DateTime.tryParse(json['joined_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'username': username,
    'avatar_url': avatarUrl,
    'status': status,
    'joined_at': joinedAt?.toIso8601String(),
  };
}

class CallModel {
  final int id;
  final int roomId;
  final String roomName;
  final String roomCode;
  final int initiatorId;
  final String initiatorName;
  final String? initiatorAvatar;
  final String callType; // 'voice', 'video'
  final String status; // 'calling', 'ringing', 'active', 'ended', 'rejected', 'failed'
  final DateTime? startedAt;
  final DateTime? endedAt;
  final List<CallParticipantModel> participants;

  CallModel({
    required this.id,
    required this.roomId,
    required this.roomName,
    this.roomCode = '',
    required this.initiatorId,
    required this.initiatorName,
    this.initiatorAvatar,
    required this.callType,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.participants = const [],
  });

  bool get isVideo => callType == 'video';
  bool get isVoice => callType == 'voice';
  bool get isActive => status == 'active';
  bool get isCalling => status == 'calling' || status == 'ringing';
  bool get isEnded => status == 'ended' || status == 'rejected';

  bool get isDirectCall => participants.where((p) => p.userId != initiatorId).length == 1;

  CallParticipantModel? get directRecipient =>
      participants.where((p) => p.userId != initiatorId).firstOrNull;

  String displayPartyName(int? currentUserId) {
    if (currentUserId != null && currentUserId == initiatorId) {
      if (isDirectCall && directRecipient != null) {
        return directRecipient!.name;
      }
      return roomName;
    } else {
      return initiatorName;
    }
  }

  String? displayPartyAvatar(int? currentUserId) {
    if (currentUserId != null && currentUserId == initiatorId) {
      if (isDirectCall && directRecipient != null) {
        return directRecipient!.avatarUrl;
      }
      return null; // Will show Group badge
    } else {
      return initiatorAvatar;
    }
  }

  factory CallModel.fromJson(Map<String, dynamic> json) {
    final rawParts = json['participants'];
    final List<CallParticipantModel> parts = [];
    if (rawParts is List) {
      for (final p in rawParts) {
        if (p is Map<String, dynamic>) {
          parts.add(CallParticipantModel.fromJson(p));
        }
      }
    }

    return CallModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      roomId: json['room_id'] is int ? json['room_id'] : int.tryParse(json['room_id'].toString()) ?? 0,
      roomName: json['room_name']?.toString() ?? 'Group',
      roomCode: json['room_code']?.toString() ?? '',
      initiatorId: json['initiator_id'] is int ? json['initiator_id'] : int.tryParse(json['initiator_id'].toString()) ?? 0,
      initiatorName: json['initiator_name']?.toString() ?? 'Member',
      initiatorAvatar: json['initiator_avatar']?.toString(),
      callType: json['call_type']?.toString() ?? 'voice',
      status: json['status']?.toString() ?? 'calling',
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'].toString()) : null,
      endedAt: json['ended_at'] != null ? DateTime.tryParse(json['ended_at'].toString()) : null,
      participants: parts,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'room_id': roomId,
    'room_name': roomName,
    'room_code': roomCode,
    'initiator_id': initiatorId,
    'initiator_name': initiatorName,
    'initiator_avatar': initiatorAvatar,
    'call_type': callType,
    'status': status,
    'started_at': startedAt?.toIso8601String(),
    'ended_at': endedAt?.toIso8601String(),
    'participants': participants.map((p) => p.toJson()).toList(),
  };
}
