import 'services/foreground_task_service.dart';
import 'services/health_sync_service.dart';
import 'services/health_average_service.dart';
import 'platform/health_connect_channel.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/health_history_service.dart';

class HealthSyncPlugin {
  static Future<void> startForegroundService() async {
    print("🟡 initForegroundTask called");
    await ForegroundTaskService.init();

    print("🟡 ensurePermissions called");
    await ForegroundTaskService.ensurePermissions();

    print("🟢 Starting foreground service...");
    await FlutterForegroundTask.startService(
      notificationTitle: 'Noscura Sync Running',
      notificationText: 'health data is syncing in the background.',
      callback: startCallback,
    );

    print("✅ Foreground service started.");
  }

  static Future<void> startSyncNow() async {
    await HealthSyncService.syncHealthData();
  }

  static Future<void> storeDailyAverage() async {
    await HealthAverageService.storeDailyAverages();
  }

  static Future<List<String>> getAvailableProviders() async {
    return await HealthConnectProvidersService.getAvailableProviders();
  }

  static Future<List<Map<String, dynamic>>> getHealthHistoryData() async {
    final fetcher = HealthHistoryFetcher();
    return await fetcher.getHealthHistory();
  }
}
