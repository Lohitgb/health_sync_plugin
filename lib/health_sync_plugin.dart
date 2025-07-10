library health_sync_plugin;

// Exporting internal service and platform files (for full Flutter apps)
export 'src/services/health_sync_service.dart';
export 'src/services/health_average_service.dart';
export 'src/platform/health_connect_channel.dart';
export 'src/services/foreground_task_service.dart';
export 'src/background/health_sync_task_handler.dart';

import 'package:health_sync_plugin/health_sync_plugin.dart';

/// Main entry point for FlutterFlow and other consumers
class HealthSyncPlugin {
  /// Initialize foreground task and permissions
  static Future<void> startForegroundService() async {
    await ForegroundTaskService.init();
    await ForegroundTaskService.ensurePermissions();
  }

  /// Manually trigger sync (optional)
  static Future<void> startSyncNow() async {
    await HealthSyncService.syncHealthData();
  }

  /// Manually store average (optional)
  static Future<void> storeDailyAverage() async {
    await HealthAverageService.storeDailyAverages();
  }

  /// Fetch available Health Connect-compatible providers
  static Future<List<String>> getAvailableProviders() async {
    return await HealthConnectProvidersService.getAvailableProviders();
  }
}
