import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/network/api_client.dart';
import 'package:mobile/src/core/storage/secure_storage_service.dart';
import 'package:mobile/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mobile/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:mobile/src/features/auth/domain/repositories/auth_repository.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) => SecureStorageService());

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ApiClient()),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider)),
);

final authSessionProvider = AsyncNotifierProvider<AuthSessionNotifier, AuthSession?>(
  AuthSessionNotifier.new,
);

class AuthSessionNotifier extends AsyncNotifier<AuthSession?> {
  static const _sessionRestoreTimeout = Duration(seconds: 8);

  @override
  Future<AuthSession?> build() async {
    // Secure storage can block the Android main thread on first access.
    // Paint the loading UI first so the native splash screen dismisses.
    await WidgetsBinding.instance.endOfFrame;

    final storage = ref.read(secureStorageProvider);
    AuthSession? cached;
    try {
      cached = await storage.readSession().timeout(_sessionRestoreTimeout);
    } on TimeoutException {
      return null;
    } catch (_) {
      try {
        await storage.clearSession().timeout(const Duration(seconds: 2));
      } catch (_) {}
      return null;
    }

    if (cached == null) return null;

    try {
      final fresh = await ref
          .read(authRepositoryProvider)
          .me(cached.token)
          .timeout(_sessionRestoreTimeout);
      await storage.saveSession(fresh);
      return fresh;
    } on TimeoutException {
      await storage.clearSession();
      return null;
    } catch (_) {
      await storage.clearSession();
      return null;
    }
  }

  Future<void> loginWithPhone({required String phone, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref.read(authRepositoryProvider).loginWithPhone(
            phone: phone,
            password: password,
          );
      await ref.read(secureStorageProvider).saveSession(session);
      return session;
    });
  }

  Future<void> loginWithUsername({required String username, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref.read(authRepositoryProvider).loginWithUsername(
            username: username,
            password: password,
          );
      await ref.read(secureStorageProvider).saveSession(session);
      return session;
    });
  }

  Future<void> register({
    required String name,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref.read(authRepositoryProvider).register(
            name: name,
            phone: phone,
            password: password,
            passwordConfirmation: passwordConfirmation,
          );
      await ref.read(secureStorageProvider).saveSession(session);
      return session;
    });
  }

  Future<void> logout() async {
    final current = state.asData?.value;
    if (current != null) {
      try {
        await ref.read(authRepositoryProvider).logout(current.token);
      } catch (_) {}
    }
    await ref.read(secureStorageProvider).clearSession();
    state = const AsyncData(null);
  }
}
