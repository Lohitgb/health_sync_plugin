import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthSyncService {
  /// Called by foreground task or scheduler to sync abnormal data
  static Future<void> syncHealthData() async {
    await _syncHealthData(); // background sync (only abnormal)
  }

  /// Called manually (e.g. by button) to force save health data
  static Future<void> manualSyncHealthData() async {
    await _syncHealthData(forceSave: true); // force save manually
  }

  /// Core method that performs health data sync
  static Future<void> _syncHealthData({bool forceSave = false}) async {
    final health = Health();
    final prefs = await SharedPreferences.getInstance();

    // Support multiple providers from shared_preferences
    final selectedProviders = prefs.getStringList('selected_providers') ?? [];

    // Fallback for old single-provider storage
    final selectedProvider = prefs.getString('selected_provider');

    // Final list of providers to consider
    final List<String> effectiveProviders = selectedProviders.isNotEmpty
        ? selectedProviders
        : (selectedProvider != null ? [selectedProvider] : []);

    // Load selected health types from preferences
    final selectedHealthTypes =
        prefs.getStringList('selected_health_types') ?? [];

    // Normal threshold constants
    const int normalHeartRateMin = 60;
    const int normalHeartRateMax = 100;
    const int normalSystolicMax = 130;
    const int normalDiastolicMax = 85;
    const double normalBloodGlucoseMax = 140.0;

    // Health data types we want to access
    final types = <HealthDataType>[];
    if (selectedHealthTypes.contains('STEPS')) {
      types.add(HealthDataType.STEPS);
    }
    if (selectedHealthTypes.contains('HEART_RATE')) {
      types.add(HealthDataType.HEART_RATE);
    }
    if (selectedHealthTypes.contains('BLOOD_PRESSURE')) {
      types.add(HealthDataType.BLOOD_PRESSURE_SYSTOLIC);
      types.add(HealthDataType.BLOOD_PRESSURE_DIASTOLIC);
    }
    if (selectedHealthTypes.contains('BLOOD_GLUCOSE')) {
      types.add(HealthDataType.BLOOD_GLUCOSE);
    }

    final permissions = List.filled(types.length, HealthDataAccess.READ);

    // Check and request permissions if not granted
    bool? hasPermission =
        await health.hasPermissions(types, permissions: permissions);

    if (hasPermission != true) {
      hasPermission =
          await health.requestAuthorization(types, permissions: permissions);
    }

    if (hasPermission != true) return;

    final now = DateTime.now();

    // Use a key based on selected providers to track last sync
    final lastSyncKey =
        'last_sync_time_${effectiveProviders.join("_") == "" ? "default" : effectiveProviders.join("_")}';
    final lastSyncStr = prefs.getString(lastSyncKey);
    final startTime = lastSyncStr != null
        ? DateTime.tryParse(lastSyncStr) ??
            DateTime(now.year, now.month, now.day)
        : DateTime(now.year, now.month, now.day);

    try {
      /// Keep track of all detected sources
      final Set<String> detectedSources = {};

      /// Function to filter data points based on selected providers
      bool isFromSelectedProviders(HealthDataPoint data) {
        final source = data.sourceName.toLowerCase();
        detectedSources.add(source);

        if (effectiveProviders.isEmpty) return true;
        return effectiveProviders.any((p) => source.contains(p.toLowerCase()));
      }

      /// ========== STEPS ==========
      int steps = 0;
      if (selectedHealthTypes.contains('STEPS')) {
        final stepData = await health.getHealthDataFromTypes(
          startTime: startTime,
          endTime: now,
          types: [HealthDataType.STEPS],
        );
        await health.removeDuplicates(stepData);

        for (var data in stepData) {
          if (data.value is NumericHealthValue &&
              isFromSelectedProviders(data)) {
            steps += (data.value as NumericHealthValue).numericValue.toInt();
          }
        }
      }

      /// ========== HEART RATE ==========
      int heartRate = 0;
      bool hrAbnormalFromAny = false;
      if (selectedHealthTypes.contains('HEART_RATE')) {
        final hrData = await health.getHealthDataFromTypes(
          startTime: startTime,
          endTime: now,
          types: [HealthDataType.HEART_RATE],
        );
        await health.removeDuplicates(hrData);

        if (hrData.isNotEmpty) {
          final sorted = hrData
              .where((d) =>
                  d.value is NumericHealthValue && isFromSelectedProviders(d))
              .toList()
            ..sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
          if (sorted.isNotEmpty) {
            heartRate =
                (sorted.first.value as NumericHealthValue).numericValue.toInt();
            hrAbnormalFromAny = heartRate > 0 &&
                (heartRate < normalHeartRateMin ||
                    heartRate > normalHeartRateMax);
          }
        }
      }

      /// ========== BLOOD PRESSURE ==========
      int? systolic;
      int? diastolic;
      bool bpAbnormalFromAny = false;

      if (selectedHealthTypes.contains('BLOOD_PRESSURE')) {
        final bpSystolicData = await health.getHealthDataFromTypes(
          startTime: startTime,
          endTime: now,
          types: [HealthDataType.BLOOD_PRESSURE_SYSTOLIC],
        );
        final bpDiastolicData = await health.getHealthDataFromTypes(
          startTime: startTime,
          endTime: now,
          types: [HealthDataType.BLOOD_PRESSURE_DIASTOLIC],
        );
        await health.removeDuplicates(bpSystolicData);
        await health.removeDuplicates(bpDiastolicData);

        if (bpSystolicData.isNotEmpty) {
          final sorted = bpSystolicData
              .where((d) =>
                  d.value is NumericHealthValue && isFromSelectedProviders(d))
              .toList()
            ..sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
          if (sorted.isNotEmpty) {
            systolic =
                (sorted.first.value as NumericHealthValue).numericValue.toInt();
          }
        }

        if (bpDiastolicData.isNotEmpty) {
          final sorted = bpDiastolicData
              .where((d) =>
                  d.value is NumericHealthValue && isFromSelectedProviders(d))
              .toList()
            ..sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
          if (sorted.isNotEmpty) {
            diastolic =
                (sorted.first.value as NumericHealthValue).numericValue.toInt();
          }
        }

        if ((systolic != null && systolic > normalSystolicMax) ||
            (diastolic != null && diastolic > normalDiastolicMax)) {
          bpAbnormalFromAny = true;
        }
      }

      /// ========== BLOOD GLUCOSE ==========
      double? bloodGlucose;
      bool glucoseAbnormalFromAny = false;
      if (selectedHealthTypes.contains('BLOOD_GLUCOSE')) {
        final glucoseData = await health.getHealthDataFromTypes(
          types: [HealthDataType.BLOOD_GLUCOSE],
          startTime: startTime,
          endTime: now,
        );
        await health.removeDuplicates(glucoseData);

        if (glucoseData.isNotEmpty) {
          final sorted = glucoseData
              .where((d) =>
                  d.value is NumericHealthValue && isFromSelectedProviders(d))
              .toList()
            ..sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
          if (sorted.isNotEmpty) {
            bloodGlucose = (sorted.first.value as NumericHealthValue)
                .numericValue
                .toDouble();
            if (bloodGlucose > normalBloodGlucoseMax) {
              glucoseAbnormalFromAny = true;
            }
          }
        }
      }

      /// Save to Firestore only if abnormal OR forced manually
      final bool isAbnormalHR = hrAbnormalFromAny;
      final bool isAbnormalBP = bpAbnormalFromAny;
      final bool isAbnormalGlucose = glucoseAbnormalFromAny;

      if (isAbnormalHR || isAbnormalBP || isAbnormalGlucose || forceSave) {
        final latestSnapshot = await FirebaseFirestore.instance
            .collection('health_data')
            .orderBy('synced_at', descending: true)
            .limit(1)
            .get();

        bool isDuplicate = false;

        if (latestSnapshot.docs.isNotEmpty) {
          final latest = latestSnapshot.docs.first.data();

          final lastHR = latest['heart_rate']?['value'];
          final lastBPsys = latest['blood_pressure']?['systolic']?['value'];
          final lastBPdia = latest['blood_pressure']?['diastolic']?['value'];
          final lastGlucose = latest['blood_glucose']?['value'];

          isDuplicate = heartRate == lastHR &&
              systolic == lastBPsys &&
              diastolic == lastBPdia &&
              bloodGlucose == lastGlucose;
        }

        /// Save new data if not duplicate OR forced
        if (!isDuplicate || forceSave) {
          if (selectedHealthTypes.contains('STEPS')) {
            await FirebaseFirestore.instance.collection('steps').add({
              'value': steps,
              'synced_at': now.toIso8601String(),
              'providers': effectiveProviders,
            });
          }

          if (selectedHealthTypes.contains('HEART_RATE')) {
            await FirebaseFirestore.instance.collection('heart_rate').add({
              'value': heartRate,
              'abnormal': isAbnormalHR,
              'synced_at': now.toIso8601String(),
              'providers': effectiveProviders,
            });
          }

          if (selectedHealthTypes.contains('BLOOD_PRESSURE')) {
            await FirebaseFirestore.instance.collection('blood_pressure').add({
              'systolic': {
                'value': systolic,
                'abnormal': isAbnormalBP,
              },
              'diastolic': {
                'value': diastolic,
                'abnormal': isAbnormalBP,
              },
              'synced_at': now.toIso8601String(),
              'providers': effectiveProviders,
            });
          }

          if (selectedHealthTypes.contains('BLOOD_GLUCOSE')) {
            await FirebaseFirestore.instance.collection('blood_glucose').add({
              'value': bloodGlucose,
              'abnormal': isAbnormalGlucose,
              'synced_at': now.toIso8601String(),
              'providers': effectiveProviders,
            });
          }

          // Update last sync time
          await prefs.setString(lastSyncKey, now.toIso8601String());
        }
      }
    } catch (e) {
      // Silently ignore for this version (avoid crash)
    }
  }
}
