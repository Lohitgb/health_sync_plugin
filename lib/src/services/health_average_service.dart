import 'package:health/health.dart';
import 'package:health_sync_plugin/src/helper/encrypt_decrypt_service.dart';
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

    // void addAverage(String label, List<double> values) {
    //   if (values.isNotEmpty) {
    //     avgMap[label] = values.reduce((a, b) => a + b) / values.length;
    //   }
    // }

    if (selectedHealthTypes.contains('HEART_RATE')) {
      final hr = filteredData
          .where((d) => d.type == HealthDataType.HEART_RATE)
          .map((d) => (d.value as NumericHealthValue).numericValue.toDouble())
          .toList();
      if (hr.isNotEmpty) {
        final heartRateAvg = hr.reduce((a, b) => a + b) / hr.length;

        // Encrypt the average value as string
        final encrypted =
            await EncryptService.encryptText(heartRateAvg.toString());

        // Store encrypted data and IV separately in Firestore-compatible format
        avgMap['heart_rate_avg'] = {
          'data': encrypted['data'],
          'iv': encrypted['iv'],
        };
      }

      // addAverage('heart_rate_avg', hr);
    }

    if (selectedHealthTypes.contains('STEPS')) {
      final steps = filteredData
          .where((d) => d.type == HealthDataType.STEPS)
          .map((d) => (d.value as NumericHealthValue).numericValue.toDouble())
          .toList();
      if (steps.isNotEmpty) {
        final stepsAvg = steps.reduce((a, b) => a + b) / steps.length;
        final encrypted = await EncryptService.encryptText(stepsAvg.toString());

        avgMap['steps_avg'] = {
          'data': encrypted['data'],
          'iv': encrypted['iv'],
        };
      }

      // addAverage('steps_avg', steps);
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

      if (systolic.isNotEmpty) {
        final systolicAvg = systolic.reduce((a, b) => a + b) / systolic.length;
        final encrypted =
            await EncryptService.encryptText(systolicAvg.toString());

        avgMap['bp_systolic_avg'] = {
          'data': encrypted['data'],
          'iv': encrypted['iv'],
        };
      }

      if (diastolic.isNotEmpty) {
        final diastolicAvg =
            diastolic.reduce((a, b) => a + b) / diastolic.length;
        final encrypted =
            await EncryptService.encryptText(diastolicAvg.toString());

        avgMap['bp_diastolic_avg'] = {
          'data': encrypted['data'],
          'iv': encrypted['iv'],
        };
      }

      // addAverage('bp_systolic_avg', systolic);
      // addAverage('bp_diastolic_avg', diastolic);
    }

    if (selectedHealthTypes.contains('BLOOD_GLUCOSE')) {
      final glucose = filteredData
          .where((d) => d.type == HealthDataType.BLOOD_GLUCOSE)
          .map((d) => (d.value as NumericHealthValue).numericValue.toDouble())
          .toList();
      if (glucose.isNotEmpty) {
        final glucoseAvg = glucose.reduce((a, b) => a + b) / glucose.length;
        final encrypted =
            await EncryptService.encryptText(glucoseAvg.toString());

        avgMap['glucose_avg'] = {
          'data': encrypted['data'],
          'iv': encrypted['iv'],
        };
      }

      // addAverage('glucose_avg', glucose);
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
