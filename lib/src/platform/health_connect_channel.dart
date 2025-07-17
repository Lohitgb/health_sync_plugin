import 'package:flutter/services.dart';

class HealthConnectProvidersService {
  static const MethodChannel _channel =
      MethodChannel('health_connect_providers');

  /// Returns a list of maps with provider package and name.
  static Future<List<Map<String, String>>> getAvailableProviders() async {
    final List<dynamic> providers =
        await _channel.invokeMethod('getAvailableProviders');

    return providers
        .map((provider) =>
            Map<String, String>.from(provider as Map<dynamic, dynamic>))
        .toList();
  }
}
