import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/src/features/auth/domain/entities/auth_session.dart';

class SecureStorageService {
  static const _tokenKey = 'auth_token';
  static const _sessionKey = 'auth_session';
  static const _ioTimeout = Duration(seconds: 5);

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  Future<T> _withTimeout<T>(Future<T> future) {
    return future.timeout(_ioTimeout);
  }

  Future<void> saveSession(AuthSession session) async {
    await _withTimeout(_storage.write(key: _tokenKey, value: session.token));
    await _withTimeout(
      _storage.write(key: _sessionKey, value: jsonEncode(session.toJson())),
    );
  }

  Future<AuthSession?> readSession() async {
    final raw = await _withTimeout(_storage.read(key: _sessionKey));
    if (raw == null) return null;
    return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clearSession() async {
    await _withTimeout(_storage.delete(key: _tokenKey));
    await _withTimeout(_storage.delete(key: _sessionKey));
  }
}
