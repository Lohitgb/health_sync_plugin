import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'health_sync_plugin_method_channel.dart';

abstract class HealthSyncPluginPlatform extends PlatformInterface {
  /// Constructs a HealthSyncPluginPlatform.
  HealthSyncPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static HealthSyncPluginPlatform _instance = MethodChannelHealthSyncPlugin();

  /// The default instance of [HealthSyncPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelHealthSyncPlugin].
  static HealthSyncPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [HealthSyncPluginPlatform] when
  /// they register themselves.
  static set instance(HealthSyncPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
