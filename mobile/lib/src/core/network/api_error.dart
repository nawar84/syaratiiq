import 'package:dio/dio.dart';

String parseApiError(Object error) {
  if (error is DioException) {
    final response = error.response;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        if (message.toLowerCase().contains('unauthenticated')) {
          return 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.';
        }
        return message;
      }
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        final first = errors.values.firstWhere(
          (value) => value is List && value.isNotEmpty,
          orElse: () => null,
        );
        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'انتهت مهلة الاتصال. تحقق من الإنترنت وحاول مجدداً.';
      case DioExceptionType.connectionError:
        return 'تعذّر الاتصال بالخادم. تأكد أن Laravel يعمل على المنفذ 8000.';
      default:
        if (response?.statusCode == 401) {
          return 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.';
        }
        if (response?.statusCode == 422) {
          return 'بيانات غير صحيحة. تحقق من رقم الهاتف وكلمة المرور.';
        }
        if (response?.statusCode == 403) {
          return 'تم رفض الدخول. قد يكون الحساب معلّقاً.';
        }
    }
  }

  return error.toString();
}
