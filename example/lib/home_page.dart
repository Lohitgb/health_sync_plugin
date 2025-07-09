import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:health_sync_plugin/health_sync_plugin.dart';
import 'package:health_sync_plugin_example/health_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ReceivePort? receivePort;
  List<String> selectedProviders = [];

  final Map<String, List<String>> manualSupportedHealthTypes = {
    'Google Fit': ['STEPS', 'HEART_RATE', 'BLOOD_PRESSURE', 'GLUCOSE'],
    'Samsung Health': ['STEPS', 'HEART_RATE', 'BLOOD_PRESSURE', 'GLUCOSE'],
    'iHealth': ['HEART_RATE', 'BLOOD_PRESSURE', 'GLUCOSE'],
    'Withings Health Mate': ['HEART_RATE', 'GLUCOSE'],
    'Zepp App': ['HEART_RATE', 'STEPS'],
    'Polar Flow': ['HEART_RATE', 'STEPS'],
    'COROS': ['HEART_RATE', 'STEPS'],
    'Suunto': ['HEART_RATE', 'STEPS'],
    'Oura': ['HEART_RATE', 'STEPS'],
    'Ultrahuman': ['HEART_RATE', 'GLUCOSE'],
    'Circular Ring': ['HEART_RATE', 'STEPS'],
    'Omron': ['BLOOD_PRESSURE', 'GLUCOSE'],
    'Dexcom': ['GLUCOSE'],
    'EufyLife': ['HEART_RATE', 'BLOOD_PRESSURE'],
    'Qardio': ['BLOOD_PRESSURE'],
    'Fitbit': ['STEPS', 'HEART_RATE', 'BLOOD_PRESSURE'],
    'OHealth': ['STEPS', 'HEART_RATE', 'BLOOD_PRESSURE'],
  };

  Future<void> _openHealthConnect() async {
    final uri = Uri.parse('android-app://com.google.android.apps.healthdata');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health Connect app not available.')),
        );
      }
    }
  }

  Future<void> _showAvailableProviders() async {
    try {
      final providers =
          await HealthConnectProvidersService.getAvailableProviders();
      final prefs = await SharedPreferences.getInstance();
      final previouslySelected =
          prefs.getStringList('selected_providers') ?? [];

      List<String> tempSelected = List.from(previouslySelected);

      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Select Health Data Providers'),
            content: providers.isEmpty
                ? const Text('No providers found.')
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: providers.length,
                      itemBuilder: (context, index) {
                        final provider = providers[index];
                        final isSelected = tempSelected.contains(provider);
                        return CheckboxListTile(
                          value: isSelected,
                          title: Text(provider),
                          onChanged: (checked) {
                            setStateDialog(() {
                              if (checked == true) {
                                tempSelected.add(provider);
                              } else {
                                tempSelected.remove(provider);
                              }
                            });
                          },
                          secondary: const Icon(Icons.health_and_safety),
                        );
                      },
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    selectedProviders = List.from(tempSelected);
                  });

                  await prefs.setStringList(
                      'selected_providers', selectedProviders);

                  if (selectedProviders.length == 1) {
                    await prefs.setString(
                        'selected_provider', selectedProviders.first);
                  } else {
                    await prefs.remove('selected_provider');
                  }

                  if (await FlutterForegroundTask.isRunningService) {
                    await FlutterForegroundTask.restartService();
                  }

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Selected: ${selectedProviders.join(", ")}')),
                  );

                  await _showHealthTypeSelectionDialog();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get providers: $e')),
      );
    }
  }

  Future<void> _showHealthTypeSelectionDialog() async {
    final prefs = await SharedPreferences.getInstance();

    Set<String> supportedHealthTypes = {};
    for (final provider in selectedProviders) {
      final types = manualSupportedHealthTypes[provider] ?? [];
      supportedHealthTypes.addAll(types);
    }

    List<String> selected = prefs.getStringList('selected_health_types') ?? [];

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Select Health Data to Sync'),
          content: supportedHealthTypes.isEmpty
              ? const Text(
                  'No supported health types found for selected providers.')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children: supportedHealthTypes.map((type) {
                      return CheckboxListTile(
                        title: Text(type.replaceAll('_', ' ')),
                        value: selected.contains(type),
                        onChanged: (checked) {
                          setStateDialog(() {
                            if (checked == true) {
                              selected.add(type);
                            } else {
                              selected.remove(type);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await prefs.setStringList('selected_health_types', selected);
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Health types saved: ${selected.join(", ")}')),
                );

                if (await FlutterForegroundTask.isRunningService) {
                  await FlutterForegroundTask.restartService();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // ignore: invalid_use_of_visible_for_testing_member
    receivePort = FlutterForegroundTask.receivePort;
    if (receivePort != null) {
      receivePort!.listen((data) {});
    }
    _loadSelectedProviders();
    startService();
  }

  Future<void> _loadSelectedProviders() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedProviders = prefs.getStringList('selected_providers') ?? [];
    });
  }

  void startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.restartService();
    } else {
      FlutterForegroundTask.startService(
        notificationTitle: 'Noscura Sync',
        notificationText: 'Syncing Medical Records in background',
        callback: startCallback,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noscura Health Sync'),
        centerTitle: true,
        backgroundColor: Colors.blue[400],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Noscura sync is running...'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openHealthConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Open Health Connect"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _showAvailableProviders,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(" Health Data Providers"),
            ),
            const SizedBox(height: 20),
            if (selectedProviders.isNotEmpty)
              Text(
                "Selected Providers: ${selectedProviders.join(', ')}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await HealthSyncService.manualSyncHealthData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Manual health data sync complete')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Manual Sync'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HealthHistoryScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[400],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Health History"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await HealthAverageService.storeDailyAverages();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Daily average stored in Firestore')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Store Avg"),
            ),
          ],
        ),
      ),
    );
  }
}
