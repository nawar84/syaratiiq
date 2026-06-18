import 'package:mobile/src/features/auth/domain/entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> loginWithPhone({required String phone, required String password});
  Future<AuthSession> loginWithUsername({required String username, required String password});
  Future<AuthSession> register({
    required String name,
    required String phone,
    required String password,
    required String passwordConfirmation,
  });
  Future<Map<String, dynamic>> requestPasswordReset({String? phone, String? username});
  Future<void> resetPassword({
    String? phone,
    String? username,
    required String code,
    required String password,
    required String passwordConfirmation,
  });
  Future<AuthSession> me(String token);
  Future<void> logout(String token);
}
