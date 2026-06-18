import 'package:dio/dio.dart';
import 'package:mobile/src/core/config/app_config.dart';
import 'package:mobile/src/core/network/api_error.dart';

class ApiClient {
  ApiClient({String? token}) : dio = _createDio(token);

  final Dio dio;

  static Dio _createDio(String? token) {
    final client = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 120),
        headers: {
          'Accept': 'application/json; charset=utf-8',
        },
        responseType: ResponseType.json,
      ),
    );

    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
          } else if (options.data is Map || options.data is List) {
            options.headers['Content-Type'] = 'application/json; charset=utf-8';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: parseApiError(error),
              message: parseApiError(error),
            ),
          );
        },
      ),
    );

    return client;
  }
}
