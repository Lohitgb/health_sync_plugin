// import 'package:flutter_test/flutter_test.dart';
// import 'package:health_sync_plugin/health_sync_plugin.dart';
// import 'package:health_sync_plugin/health_sync_plugin_platform_interface.dart';
// import 'package:health_sync_plugin/health_sync_plugin_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockHealthSyncPluginPlatform
//     with MockPlatformInterfaceMixin
//     implements HealthSyncPluginPlatform {

//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

// void main() {
//   final HealthSyncPluginPlatform initialPlatform = HealthSyncPluginPlatform.instance;

//   test('$MethodChannelHealthSyncPlugin is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelHealthSyncPlugin>());
//   });

//   test('getPlatformVersion', () async {
//     HealthSyncPlugin healthSyncPlugin = HealthSyncPlugin();
//     MockHealthSyncPluginPlatform fakePlatform = MockHealthSyncPluginPlatform();
//     HealthSyncPluginPlatform.instance = fakePlatform;

//     expect(await healthSyncPlugin.getPlatformVersion(), '42');
//   });
// }
