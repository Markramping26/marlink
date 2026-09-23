import 'room_member_model.dart';

class RoomModel {
  final int id;
  final String code; // e.g. FAM-82K4
  final String name;
  final String? description;
  final String? avatarUrl;
  final int createdBy;
  final bool isActive;
  final int membersCount;
  final List<RoomMemberModel> members;
  final String? currentUserRole;
  final DateTime? createdAt;

  RoomModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.createdBy,
    this.isActive = true,
    this.membersCount = 1,
    this.members = const [],
    this.currentUserRole,
    this.createdAt,
  });

  bool get isCurrentUserAdmin => currentUserRole == 'owner' || currentUserRole == 'admin';

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    var memberList = <RoomMemberModel>[];
    if (json['members'] is List) {
      memberList = (json['members'] as List)
          .map((m) => RoomMemberModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return RoomModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      createdBy: json['created_by'] is int
          ? json['created_by']
          : (int.tryParse(json['created_by']?.toString() ?? '') ?? 0),
      isActive: json['is_active'] is bool ? json['is_active'] : (json['is_active'] == 1),
      membersCount: json['members_count'] is int
          ? json['members_count']
          : (int.tryParse(json['members_count']?.toString() ?? '') ?? memberList.length),
      members: memberList,
      currentUserRole: json['current_user_role']?.toString() ?? 'member',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
