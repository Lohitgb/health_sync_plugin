import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:health_sync_plugin/health_sync_plugin.dart';
import 'package:health_sync_plugin_example/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // ✅ Firebase initialization
  await ForegroundTaskService.init();
  await ForegroundTaskService.ensurePermissions();

  runApp(const HealthExampleApp());
}

class HealthExampleApp extends StatelessWidget {
  const HealthExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Sync Plugin Demo',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const MyHomePage(title: 'Noscura Sync App'),
      debugShowCheckedModeBanner: false,
    );
  }
}
