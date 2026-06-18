import 'package:mobile/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:mobile/src/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<AuthSession> loginWithPhone({required String phone, required String password}) {
    return _remote.loginWithPhone(phone: phone, password: password);
  }

  @override
  Future<AuthSession> loginWithUsername({required String username, required String password}) {
    return _remote.loginWithUsername(username: username, password: password);
  }

  @override
  Future<AuthSession> me(String token) {
    return _remote.me(token);
  }

  @override
  Future<void> logout(String token) {
    return _remote.logout(token);
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) {
    return _remote.register(
      name: name,
      phone: phone,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }

  @override
  Future<Map<String, dynamic>> requestPasswordReset({String? phone, String? username}) {
    return _remote.requestPasswordReset(phone: phone, username: username);
  }

  @override
  Future<void> resetPassword({
    String? phone,
    String? username,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) {
    return _remote.resetPassword(
      phone: phone,
      username: username,
      code: code,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }
}
