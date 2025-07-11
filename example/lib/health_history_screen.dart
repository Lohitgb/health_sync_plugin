import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthHistoryScreen extends StatefulWidget {
  const HealthHistoryScreen({super.key});

  @override
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  final Health _health = Health(); // Health Connect interface
  List<HealthDataPoint> _filteredData = []; // Filtered data to display
  bool _loading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _loadHistory(); // Load data on screen load
  }

  Future<void> _showDynamicAverageAnalysis() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedTypes = prefs.getStringList('selected_health_types') ?? [];

    if (selectedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No selected health types to analyze.")),
      );
      return;
    }

    Map<String, double> averages = {};

    for (String type in selectedTypes) {
      final matchingData = _filteredData.where((d) {
        switch (type) {
          case 'HEART_RATE':
            return d.type == HealthDataType.HEART_RATE;
          case 'STEPS':
            return d.type == HealthDataType.STEPS;
          case 'BLOOD_GLUCOSE':
            return d.type == HealthDataType.BLOOD_GLUCOSE;
          case 'BLOOD_PRESSURE':
            return d.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC ||
                d.type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC;
          default:
            return false;
        }
      }).where((d) => d.value is NumericHealthValue);

      if (matchingData.isNotEmpty) {
        final values = matchingData
            .map((d) => (d.value as NumericHealthValue).numericValue)
            .toList();

        final avg = values.reduce((a, b) => a + b) / values.length;

        if (type == 'BLOOD_PRESSURE') {
          final systolic = matchingData
              .where((d) => d.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC)
              .map((d) => (d.value as NumericHealthValue).numericValue)
              .toList();
          final diastolic = matchingData
              .where((d) => d.type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC)
              .map((d) => (d.value as NumericHealthValue).numericValue)
              .toList();

          if (systolic.isNotEmpty) {
            final avgS = systolic.reduce((a, b) => a + b) / systolic.length;
            averages['Systolic BP'] = avgS;
          }
          if (diastolic.isNotEmpty) {
            final avgD = diastolic.reduce((a, b) => a + b) / diastolic.length;
            averages['Diastolic BP'] = avgD;
          }
        } else {
          averages[type.replaceAll('_', ' ').toUpperCase()] = avg;
        }
      }
    }

    if (averages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No data found for selected types.")),
      );
      return;
    }

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Average Analysis (24 hrs)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: averages.entries.map((e) {
            return Text("${e.key}: ${e.value.toStringAsFixed(1)}");
          }).toList(),
        ),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  /// Loads the last 24 hours of health data for selected providers
  Future<void> _loadHistory() async {
    setState(() => _loading = true);

    // Get selected providers from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final selectedProviders = prefs.getStringList('selected_providers') ?? [];

    // Get selected health types from SharedPreferences
    final selectedHealthTypes =
        prefs.getStringList('selected_health_types') ?? [];

    // Build health data types dynamically based on selection
    final List<HealthDataType> types = [];

    if (selectedHealthTypes.contains('HEART_RATE')) {
      types.add(HealthDataType.HEART_RATE);
    }
    if (selectedHealthTypes.contains('STEPS')) {
      types.add(HealthDataType.STEPS);
    }
    if (selectedHealthTypes.contains('BLOOD_PRESSURE')) {
      types.add(HealthDataType.BLOOD_PRESSURE_SYSTOLIC);
      types.add(HealthDataType.BLOOD_PRESSURE_DIASTOLIC);
    }
    if (selectedHealthTypes.contains('BLOOD_GLUCOSE')) {
      types.add(HealthDataType.BLOOD_GLUCOSE);
    }

    // Define access type (READ only)
    final permissions = List.filled(types.length, HealthDataAccess.READ);

    // Check and request permission if needed
    bool? hasPermission =
        await _health.hasPermissions(types, permissions: permissions);
    if (hasPermission != true) {
      hasPermission =
          await _health.requestAuthorization(types, permissions: permissions);
    }

    // Exit if permission still not granted
    if (hasPermission != true) {
      setState(() => _loading = false);
      return;
    }

    final now = DateTime.now();
    final startTime = now.subtract(const Duration(hours: 24)); // 24hr range

    // Fetch health data between (now - 24hr) and now
    final healthData = await _health.getHealthDataFromTypes(
      startTime: startTime,
      endTime: now,
      types: types,
    );

    // Remove any duplicates from the data
    await _health.removeDuplicates(healthData);

    // Filter by selected app providers (e.g., iHealth, Google Fit, etc.)
    List<HealthDataPoint> filtered = healthData.where((data) {
      final source = data.sourceName.toLowerCase();
      if (selectedProviders.isEmpty) return true;
      return selectedProviders.any((p) => source.contains(p.toLowerCase()));
    }).toList();

    // Update UI with the filtered data
    setState(() {
      _filteredData = filtered;
      _loading = false;
    });
  }

  /// Builds a list item widget for each health data point
  Widget _buildItem(HealthDataPoint data) {
    final formatter = DateFormat('dd MMM, hh:mm a');
    final fromTime = formatter.format(data.dateFrom);
    // final toTime = formatter.format(data.dateTo);

    return ListTile(
      title: Text('${data.typeString}: ${data.value}'),
      subtitle: Text(
        'From: ${data.sourceName}\nTime: $fromTime',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health History"),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator()) // Loading state
          : _filteredData.isEmpty
              ? const Center(child: Text("No data available.")) // No data
              : ListView.builder(
                  itemCount: _filteredData.length,
                  itemBuilder: (_, index) => _buildItem(_filteredData[index]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showDynamicAverageAnalysis,
        icon: const Icon(Icons.analytics),
        label: const Text("Analyze Avg"),
      ),
    );
  }
}
