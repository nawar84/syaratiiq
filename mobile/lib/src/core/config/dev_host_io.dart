import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:mobile/src/core/config/app_config.dart';

Future<String> resolveDevHost() async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    return androidInfo.isPhysicalDevice ? AppConfig.devLanHost : '10.0.2.2';
  }

  if (Platform.isIOS) {
    final iosInfo = await DeviceInfoPlugin().iosInfo;
    return iosInfo.isPhysicalDevice ? AppConfig.devLanHost : '127.0.0.1';
  }

  return '127.0.0.1';
}
