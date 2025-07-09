import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/health_sync_service.dart';
import '../services/health_average_service.dart'; // Uncommented to use average storing

/// Task handler that defines background sync + average logic
class HealthSyncTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  bool _initialized = false;
  DateTime? _lastAvgRun; // Track last average run

  /// Called once when the foreground task starts
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter taskStarter) async {
    _sendPort = await FlutterForegroundTask.getData<SendPort>(key: 'sendPort');

    // Initialize Firebase if not already done (important in background isolates)
    if (!_initialized) {
      try {
        await Firebase.initializeApp();
        _initialized = true;
      } catch (e) {
        print('Firebase already initialized or error: $e');
      }
    }

    _sendPort?.send("startTask");

    // Perform initial sync
    await HealthSyncService.syncHealthData();
  }

  /// Called periodically based on the configured repeat interval
  @override
  void onRepeatEvent(DateTime timestamp) async {
    print('⏰ Foreground onRepeatEvent: syncing health data...');
    await HealthSyncService.syncHealthData();

    // Run once daily after 12 PM to store averages
    final now = DateTime.now();
    final target12PM = DateTime(now.year, now.month, now.day, 12);

    if (now.isAfter(target12PM) &&
        (_lastAvgRun == null || _lastAvgRun!.day != now.day)) {
      print('📊 Storing daily average at 12 PM...');
      await HealthAverageService.storeDailyAverages();
      _lastAvgRun = now;
    }
  }

  /// Called when the service is stopped or destroyed
  @override
  Future<void> onDestroy(DateTime timestamp, bool isForeground) async {
    _sendPort?.send("killTask");
    FlutterForegroundTask.stopService();
  }

  /// Called when a button in the notification is pressed
  @override
  void onNotificationButtonPressed(String id) {
    _sendPort?.send("killTask");
  }

  /// Called when the user taps the notification
  @override
  void onNotificationPressed() {
    _sendPort?.send('onNotificationPressed');
    FlutterForegroundTask.stopService();
  }
}
