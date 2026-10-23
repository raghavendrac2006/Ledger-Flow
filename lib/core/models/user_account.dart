enum UserRole { admin, worker }

class UserAccount {
  final String id;
  final String email;
  final String passwordHash;
  final String name;
  final UserRole role;
  final String? pin; // 4-digit PIN for quick switch
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserAccount({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.name,
    required this.role,
    this.pin,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isWorker => role == UserRole.worker;

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'passwordHash': passwordHash,
      'name': name,
      'role': role == UserRole.admin ? 'admin' : 'worker',
      'pin': pin,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  factory UserAccount.fromMap(String id, Map<String, dynamic> map) {
    return UserAccount(
      id: id,
      email: map['email'] ?? '',
      passwordHash: map['passwordHash'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.worker,
      pin: map['pin'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.parse(map['lastLoginAt'])
          : null,
    );
  }

  UserAccount copyWith({
    String? email,
    String? passwordHash,
    String? name,
    UserRole? role,
    String? pin,
    bool? isActive,
    DateTime? lastLoginAt,
  }) {
    return UserAccount(
      id: id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      name: name ?? this.name,
      role: role ?? this.role,
      pin: pin ?? this.pin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
