import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HealthAverageService {
  /// Fetches health data for selected types, calculates averages, and stores in Firestore
  static Future<void> storeDailyAverages() async {
    final health = Health();
    final prefs = await SharedPreferences.getInstance();

    // Get selected providers and types from SharedPreferences
    final selectedProviders = prefs.getStringList('selected_providers') ?? [];
    final selectedHealthTypes =
        prefs.getStringList('selected_health_types') ?? [];

    // Build dynamic list of types to fetch
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

    // Request permission
    final permissions = List.filled(types.length, HealthDataAccess.READ);
    bool? hasPermission =
        await health.hasPermissions(types, permissions: permissions);
    if (hasPermission != true) {
      hasPermission =
          await health.requestAuthorization(types, permissions: permissions);
    }
    if (hasPermission != true) return;

    final now = DateTime.now();
    final startTime = now.subtract(const Duration(hours: 24));

    // Fetch data
    final data = await health.getHealthDataFromTypes(
      startTime: startTime,
      endTime: now,
      types: types,
    );

    await health.removeDuplicates(data);

    // Filter by selected providers
    final filteredData = data.where((d) {
      final source = d.sourceName.toLowerCase();
      return selectedProviders.any((p) => source.contains(p.toLowerCase()));
    }).toList();

    // Calculate averages
    final Map<String, dynamic> avgMap = {};

    void addAverage(String label, List<double> values) {
      if (values.isNotEmpty) {
        avgMap[label] = values.reduce((a, b) => a + b) / values.length;
      }
    }

    if (selectedHealthTypes.contains('HEART_RATE')) {
      final hr = filteredData
          .where((d) => d.type == HealthDataType.HEART_RATE)
          .map((d) => (d.value as NumericHealthValue).numericValue.toDouble())
          .toList();
      addAverage('heart_rate_avg', hr);
    }

    if (selectedHealthTypes.contains('STEPS')) {
      final steps = filteredData
          .where((d) => d.type == HealthDataType.STEPS)
          .map((d) => (d.value as NumericHealthValue).numericValue.toDouble())
          .toList();
      addAverage('steps_avg', steps);
    }

    if (selectedHealthTypes.contains('BLOOD_PRESSURE')) {
      final systolic = filteredData
          .where((d) => d.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC)
          .map((d) => (d.value as NumericHealthValue).numericValue.toDouble())
          .toList();
      final diastolic = filteredData
          .where((d) => d.type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC)
          .map((d) => (d.value as NumericHealthValue).numericValue.toDouble())
          .toList();

      addAverage('bp_systolic_avg', systolic);
      addAverage('bp_diastolic_avg', diastolic);
    }

    if (selectedHealthTypes.contains('BLOOD_GLUCOSE')) {
      final glucose = filteredData
          .where((d) => d.type == HealthDataType.BLOOD_GLUCOSE)
          .map((d) => (d.value as NumericHealthValue).numericValue.toDouble())
          .toList();
      addAverage('glucose_avg', glucose);
    }

    // Store result in Firestore
    if (avgMap.isNotEmpty) {
      await FirebaseFirestore.instance.collection('daily_health_avg').add({
        'timestamp': DateTime.now().toIso8601String(),
        'data': avgMap,
      });
    }
  }
}
