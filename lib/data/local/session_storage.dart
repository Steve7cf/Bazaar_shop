import 'package:shared_preferences/shared_preferences.dart';

const _sessionUserIdKey = 'bazaar.session_user_id';

class SessionStorage {
  SessionStorage._();
  static final SessionStorage instance = SessionStorage._();

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionUserIdKey, userId);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionUserIdKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionUserIdKey);
  }
}
