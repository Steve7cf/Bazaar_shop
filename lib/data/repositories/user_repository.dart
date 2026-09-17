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
  }) async {
    final db = await AppDatabase.instance.database;
    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    final user = AppUser(
      id: 'usr_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      name: name.trim(),
      email: email.toLowerCase().trim(),
      passwordHash: hash,
      role: role,
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
}
