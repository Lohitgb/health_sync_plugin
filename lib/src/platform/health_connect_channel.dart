import 'package:flutter/services.dart';

/// Wrapper for native method channel to fetch installed Health Connect-compatible apps
class HealthConnectProvidersService {
  static const MethodChannel _channel =
      MethodChannel('health_connect_providers');

  /// Returns a list of provider app names (e.g., Google Fit, Samsung Health)
  static Future<List<String>> getAvailableProviders() async {
    final List<dynamic> providers =
        await _channel.invokeMethod('getAvailableProviders');
    return providers.cast<String>();
  }
}
