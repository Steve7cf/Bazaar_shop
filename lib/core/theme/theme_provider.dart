import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/session_storage.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/user_repository.dart';

const _themePrefsKey = 'bazaar.theme_preference';

/// Theme choice — Light / Dark / Follow system — persisted on the logged-in
/// user's row (`users.theme`), matching the original's "persisted per-user,
/// applied on login" behavior. Before any user is logged in (splash/login
/// screens), falls back to a local device-level preference so the app still
/// has a sensible theme to show.
class ThemeModeNotifier extends Notifier<AppThemePreference> {
  @override
  AppThemePreference build() {
    _loadInitial();
    return AppThemePreference.system;
  }

  Future<void> _loadInitial() async {
    final userId = await SessionStorage.instance.getUserId();
    if (userId != null) {
      final user = await UserRepository.instance.findById(userId);
      if (user != null) {
        state = user.theme;
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themePrefsKey);
    state = AppThemePreferenceValue.fromValue(saved);
  }

  /// Called right after login/admin-setup so the newly active session's
  /// saved theme takes over immediately.
  void applyForUser(AppUser user) {
    state = user.theme;
  }

  Future<void> setPreference(AppThemePreference preference) async {
    state = preference;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefsKey, preference.value);

    final userId = await SessionStorage.instance.getUserId();
    if (userId != null) {
      await UserRepository.instance.updateTheme(userId, preference);
    }
  }
}

final themePreferenceProvider =
    NotifierProvider<ThemeModeNotifier, AppThemePreference>(
      ThemeModeNotifier.new,
    );

/// Convenience derived provider — what MaterialApp.themeMode actually wants.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themePreferenceProvider).themeMode;
});
