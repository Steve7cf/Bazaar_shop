enum UserRole { admin, cashier }

extension UserRoleValue on UserRole {
  String get value => switch (this) {
    UserRole.admin => 'admin',
    UserRole.cashier => 'cashier',
  };

  static UserRole fromValue(String v) =>
      v == 'admin' ? UserRole.admin : UserRole.cashier;
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final UserRole role;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.createdAt,
  });

  factory AppUser.fromRow(Map<String, Object?> row) {
    return AppUser(
      id: row['id'] as String,
      name: row['name'] as String,
      email: row['email'] as String,
      passwordHash: row['password_hash'] as String,
      role: UserRoleValue.fromValue(row['role'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Map<String, Object?> toRow() => {
    'id': id,
    'name': name,
    'email': email,
    'password_hash': passwordHash,
    'role': role.value,
    'created_at': createdAt.toIso8601String(),
  };
}
