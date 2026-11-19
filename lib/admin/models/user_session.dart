enum UserRole {
  subscriber,
  groupMember,
  platformAdmin,
  unknown;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'platformadmin':
      case 'platform_admin':
      case 'platform admin':
        return UserRole.platformAdmin;
      case 'groupmember':
      case 'member':
      case 'student':
        return UserRole.groupMember;
      case 'subscriber':
      case 'admin':
      case 'teacher':
        return UserRole.subscriber;
      default:
        return UserRole.unknown;
    }
  }

  String toDisplayString() {
    switch (this) {
      case UserRole.platformAdmin:
        return 'Platform Admin';
      case UserRole.groupMember:
        return 'Student / Member';
      case UserRole.subscriber:
        return 'Subscriber / Tutor';
      case UserRole.unknown:
        return 'Unknown';
    }
  }
}

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['name'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String? ?? 'Unknown'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'role': role.name,
  };
}

class UserSession {
  final String token;
  final UserProfile user;

  const UserSession({required this.token, required this.user});

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      token: json['token'] as String? ?? '',
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {'token': token, 'user': user.toJson()};
}
