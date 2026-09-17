import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/session_storage.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/user_repository.dart';

export '../../../data/models/app_user.dart' show UserRole;

typedef SessionUser = AppUser;

final hasAnyUserProvider = FutureProvider<bool>((ref) async {
  final count = await UserRepository.instance.countUsers();
  return count > 0;
});

final sessionProvider = FutureProvider<AppUser?>((ref) async {
  final userId = await SessionStorage.instance.getUserId();
  if (userId == null) return null;
  return UserRepository.instance.findById(userId);
});

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await UserRepository.instance.verifyCredentials(
        email,
        password,
      );
      if (user == null) {
        state = const AsyncValue.data(null);
        return false;
      }
      await SessionStorage.instance.saveUserId(user.id);
      ref.invalidate(sessionProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> setupAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final existing = await UserRepository.instance.findByEmail(email);
      if (existing != null) {
        state = const AsyncValue.data(null);
        return false;
      }
      final user = await UserRepository.instance.createUser(
        name: name,
        email: email,
        password: password,
        role: UserRole.admin,
      );
      await SessionStorage.instance.saveUserId(user.id);
      ref.invalidate(hasAnyUserProvider);
      ref.invalidate(sessionProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> logout() async {
    await SessionStorage.instance.clear();
    ref.invalidate(sessionProvider);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);
