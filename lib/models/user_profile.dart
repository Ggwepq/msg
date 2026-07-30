enum UserRole { admin, friend }

class UserProfile {
  final String id;
  final String nickname;
  final UserRole role;
  final String? accessKey;
  final DateTime lastSeen;

  UserProfile({
    required this.id,
    required this.nickname,
    required this.role,
    this.accessKey,
    required this.lastSeen,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'role': role.name,
        'accessKey': accessKey,
        'lastSeen': lastSeen.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        nickname: json['nickname'] as String,
        role: json['role'] == 'admin' ? UserRole.admin : UserRole.friend,
        accessKey: json['accessKey'] as String?,
        lastSeen: DateTime.parse(json['lastSeen'] as String),
      );
}
