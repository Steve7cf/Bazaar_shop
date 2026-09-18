import 'package:flutter/material.dart';

enum UserRole { admin, cashier }

extension UserRoleValue on UserRole {
  String get value => switch (this) {
    UserRole.admin => 'admin',
    UserRole.cashier => 'cashier',
  };

  static UserRole fromValue(String v) =>
      v == 'admin' ? UserRole.admin : UserRole.cashier;
}

/// Mirrors the original web app's per-user `theme` preference, extended with
/// a `system` option (the original only had light/dark).
enum AppThemePreference { light, dark, system }

extension AppThemePreferenceValue on AppThemePreference {
  String get value => switch (this) {
    AppThemePreference.light => 'light',
    AppThemePreference.dark => 'dark',
    AppThemePreference.system => 'system',
  };

  ThemeMode get themeMode => switch (this) {
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
    AppThemePreference.system => ThemeMode.system,
  };

  static AppThemePreference fromValue(String? v) => switch (v) {
    'light' => AppThemePreference.light,
    'dark' => AppThemePreference.dark,
    _ => AppThemePreference.system,
  };
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final UserRole role;
  final AppThemePreference theme;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.theme,
    required this.createdAt,
  });

  AppUser copyWith({AppThemePreference? theme}) {
    return AppUser(
      id: id,
      name: name,
      email: email,
      passwordHash: passwordHash,
      role: role,
      theme: theme ?? this.theme,
      createdAt: createdAt,
    );
  }

  factory AppUser.fromRow(Map<String, Object?> row) {
    return AppUser(
      id: row['id'] as String,
      name: row['name'] as String,
      email: row['email'] as String,
      passwordHash: row['password_hash'] as String,
      role: UserRoleValue.fromValue(row['role'] as String),
      theme: AppThemePreferenceValue.fromValue(row['theme'] as String?),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Map<String, Object?> toRow() => {
    'id': id,
    'name': name,
    'email': email,
    'password_hash': passwordHash,
    'role': role.value,
    'theme': theme.value,
    'created_at': createdAt.toIso8601String(),
  };
}
