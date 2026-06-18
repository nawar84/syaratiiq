import 'package:mobile/src/core/network/api_client.dart';
import 'package:mobile/src/features/auth/domain/entities/auth_session.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final ApiClient _client;

  Future<AuthSession> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    final response = await _client.dio.post('/login', data: {
      'phone': phone,
      'password': password,
    });
    return _sessionFromPayload(response.data as Map<String, dynamic>);
  }

  Future<AuthSession> loginWithUsername({
    required String username,
    required String password,
  }) async {
    final response = await _client.dio.post('/login', data: {
      'username': username,
      'password': password,
    });
    return _sessionFromPayload(response.data as Map<String, dynamic>);
  }

  Future<AuthSession> register({
    required String name,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _client.dio.post('/register', data: {
      'name': name,
      'phone': phone,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    return _sessionFromPayload(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> requestPasswordReset({
    String? phone,
    String? username,
  }) async {
    final response = await _client.dio.post('/forgot-password', data: {
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (username != null && username.isNotEmpty) 'username': username,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> resetPassword({
    String? phone,
    String? username,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _client.dio.post('/reset-password', data: {
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (username != null && username.isNotEmpty) 'username': username,
      'code': code,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  Future<void> logout(String token) async {
    await ApiClient(token: token).dio.post('/logout');
  }

  Future<AuthSession> me(String token) async {
    final response = await ApiClient(token: token).dio.get('/me');
    final user = response.data as Map<String, dynamic>;
    return AuthSession(
      token: token,
      id: user['id'] as int,
      name: user['name'] as String,
      phone: user['phone'] as String,
      role: user['role'] as String,
      username: user['username'] as String?,
      accountStatus: user['account_status'] as String?,
      canManageCars: user['can_manage_cars'] as bool? ?? true,
      subscriptionEnd: user['subscription_end']?.toString(),
      showroomName: user['showroom_name'] as String?,
    );
  }

  AuthSession _sessionFromPayload(Map<String, dynamic> payload) {
    final user = payload['user'] as Map<String, dynamic>;
    return AuthSession(
      token: payload['token'] as String,
      id: user['id'] as int,
      name: user['name'] as String,
      phone: user['phone'] as String,
      role: user['role'] as String,
      username: user['username'] as String?,
      accountStatus: user['account_status'] as String?,
      canManageCars: user['can_manage_cars'] as bool? ?? true,
      subscriptionEnd: user['subscription_end']?.toString(),
      showroomName: user['showroom_name'] as String?,
    );
  }
}
