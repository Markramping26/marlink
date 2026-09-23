import 'user_profile_model.dart';

class UserModel {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? phone;
  final bool isActive;
  final UserProfileModel? profile;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.phone,
    this.isActive = true,
    this.profile,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      isActive: json['is_active'] ?? true,
      profile: json['profile'] != null
          ? UserProfileModel.fromJson(json['profile'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'email': email,
        'phone': phone,
        'is_active': isActive,
        'profile': profile?.toJson(),
        'created_at': createdAt?.toIso8601String(),
      };

  UserModel copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    String? phone,
    bool? isActive,
    UserProfileModel? profile,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      profile: profile ?? this.profile,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

