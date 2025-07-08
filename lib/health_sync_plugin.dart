
import 'health_sync_plugin_platform_interface.dart';

class HealthSyncPlugin {
  Future<String?> getPlatformVersion() {
    return HealthSyncPluginPlatform.instance.getPlatformVersion();
  }
}
