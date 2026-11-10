enum UserRole {
  subscriber,
  groupMember,
  platformAdmin;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'platformadmin':
        return UserRole.platformAdmin;
      case 'groupmember':
        return UserRole.groupMember;
      case 'subscriber':
      default:
        return UserRole.subscriber;
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
      role: UserRole.fromString(json['role'] as String? ?? 'Subscriber'),
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

  const UserSession({
    required this.token,
    required this.user,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      token: json['token'] as String? ?? '',
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'user': user.toJson(),
  };
}

