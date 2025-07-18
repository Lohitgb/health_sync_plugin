import 'package:flutter/services.dart';

class OpenHealthConnectApp {
  static const MethodChannel _channel = MethodChannel('health_connect_channel');

  static Future<bool> openHealthConnect() async {
    try {
      final bool result = await _channel.invokeMethod('openHealthConnect');
      return result;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
