import 'services/foreground_task_service.dart';
import 'services/health_sync_service.dart';
import 'services/health_average_service.dart';
import 'platform/health_connect_channel.dart';

class HealthSyncPlugin {
  static Future<void> startForegroundService() async {
    await ForegroundTaskService.init();
    await ForegroundTaskService.ensurePermissions();
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
}
