import 'package:flutter/foundation.dart';
import 'package:mobile/src/core/config/dev_host.dart';

class AppConfig {
  AppConfig._();

  static const String appName = 'سياراتي IQ';

  /// Full API URL override: --dart-define=API_BASE_URL=https://api.example.com/api
  static const String _baseUrlFromEnv = String.fromEnvironment('API_BASE_URL');

  /// Host override: --dart-define=API_HOST=api.example.com
  static const String _hostFromEnv = String.fromEnvironment('API_HOST');

  /// Port override: --dart-define=API_PORT=443
  static const String _portFromEnv = String.fromEnvironment('API_PORT', defaultValue: '8000');

  /// Scheme override: --dart-define=API_SCHEME=https
  static const String _schemeFromEnv = String.fromEnvironment('API_SCHEME');

  /// Dev-only fallback when no dart-define is provided on a physical device.
  static const String devLanHost = String.fromEnvironment(
    'DEV_LAN_HOST',
    defaultValue: '192.168.68.100',
  );

  static late final String apiBaseUrl;

  static Future<void> init() async {
    if (_baseUrlFromEnv.isNotEmpty) {
      apiBaseUrl = _normalizeBaseUrl(_baseUrlFromEnv);
      return;
    }

    if (_hostFromEnv.isNotEmpty) {
      apiBaseUrl = _buildUrl(host: _hostFromEnv, port: _portFromEnv);
      return;
    }

    if (kReleaseMode) {
      throw StateError(
        'Production build requires API_BASE_URL or API_HOST. '
        'Example: flutter build web --dart-define=API_BASE_URL=https://syaratiiq.com/api',
      );
    }

    apiBaseUrl = _buildUrl(host: await resolveDevHost(), port: _portFromEnv);
  }

  static String _buildUrl({required String host, required String port}) {
    final scheme = _schemeFromEnv.isNotEmpty
        ? _schemeFromEnv
        : (port == '443' ? 'https' : 'http');
    final base = scheme == 'https' && port == '443'
        ? '$scheme://$host'
        : '$scheme://$host:$port';
    return '$base/api';
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'/+$'), '');
    return trimmed.endsWith('/api') ? trimmed : '$trimmed/api';
  }
}
