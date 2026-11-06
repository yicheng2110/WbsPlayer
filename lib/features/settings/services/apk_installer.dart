import 'package:flutter/services.dart';

class ApkInstaller {
  static const _channel = MethodChannel('wbs_player/apk_installer');

  const ApkInstaller._();

  static Future<String> install(String apkPath) async =>
      await _channel.invokeMethod<String>('installApk', {'path': apkPath}) ??
      'error';
}
