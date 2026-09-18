import 'package:bcrypt/bcrypt.dart';
import '../local/app_database.dart';
import '../models/app_user.dart';

class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  Future<int> countUsers() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM users');
    final value = result.first['c'];
    return value is int ? value : (value as num).toInt();
  }

  Future<AppUser?> findByEmail(String email) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase().trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppUser.fromRow(rows.first);
  }

  Future<AppUser?> findById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppUser.fromRow(rows.first);
  }

  Future<AppUser> createUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    AppThemePreference theme = AppThemePreference.system,
  }) async {
    final db = await AppDatabase.instance.database;
    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    final user = AppUser(
      id: 'usr_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      name: name.trim(),
      email: email.toLowerCase().trim(),
      passwordHash: hash,
      role: role,
      theme: theme,
      createdAt: DateTime.now(),
    );
    await db.insert('users', user.toRow());
    return user;
  }

  /// Returns the user if credentials match, else null.
  Future<AppUser?> verifyCredentials(String email, String password) async {
    final user = await findByEmail(email);
    if (user == null) return null;
    final ok = BCrypt.checkpw(password, user.passwordHash);
    return ok ? user : null;
  }

  /// Persists the theme choice on the logged-in user's row — matches the
  /// original's "persisted per-user, applied on login" behavior.
  Future<void> updateTheme(String userId, AppThemePreference theme) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'users',
      {'theme': theme.value},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<bool> updatePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = await findById(userId);
    if (user == null) return false;
    final ok = BCrypt.checkpw(currentPassword, user.passwordHash);
    if (!ok) return false;
    final db = await AppDatabase.instance.database;
    final newHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
    await db.update(
      'users',
      {'password_hash': newHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return true;
  }
}
