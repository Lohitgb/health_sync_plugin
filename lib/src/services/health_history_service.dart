import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HealthHistoryFetcher {
  final Health _health = Health();

  Future<List<Map<String, dynamic>>> getHealthHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedProviders = prefs.getStringList('selected_providers') ?? [];
      final selectedDevices = prefs.getStringList('selected_devices') ?? [];

      // Extract unique types from selected_devices
      final selectedTypesRaw = selectedDevices
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .map((d) => d['type'] as String)
          .toSet()
          .toList();

      // Return empty if no device types selected
      if (selectedTypesRaw.isEmpty) {
        return [];
      }

      // Map normalized type names (saved) to HealthDataType enums
      // Note: Blood pressure has SYSTOLIC and DIASTOLIC separately, 
      // so if user selects "BLOOD_PRESSURE", include both.

      List<HealthDataType> typesToRequest = [];

      for (var t in selectedTypesRaw) {
        switch (t) {
          case 'HEART_RATE':
            typesToRequest.add(HealthDataType.HEART_RATE);
            break;
          case 'STEPS':
            typesToRequest.add(HealthDataType.STEPS);
            break;
          case 'BLOOD_GLUCOSE':
            typesToRequest.add(HealthDataType.BLOOD_GLUCOSE);
            break;
          case 'BLOOD_PRESSURE':
            // Expand BP to both systolic and diastolic
            typesToRequest.add(HealthDataType.BLOOD_PRESSURE_SYSTOLIC);
            typesToRequest.add(HealthDataType.BLOOD_PRESSURE_DIASTOLIC);
            break;
          default:
            // Optionally handle unknown or custom types here
            break;
        }
      }

      if (typesToRequest.isEmpty) {
        return [];
      }

      final permissions = List.filled(typesToRequest.length, HealthDataAccess.READ);

      bool? hasPermission = await _health.hasPermissions(
        typesToRequest,
        permissions: permissions,
      );

      if (hasPermission != true) {
        hasPermission = await _health.requestAuthorization(
          typesToRequest,
          permissions: permissions,
        );
      }

      if (hasPermission != true) return [];

      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 24));

      final rawData = await _health.getHealthDataFromTypes(
        startTime: startTime,
        endTime: now,
        types: typesToRequest,
      );

      await _health.removeDuplicates(rawData);

      // Filter by selected providers (source names)
      final filtered = rawData.where((data) {
        if (selectedProviders.isEmpty) return true;
        final source = data.sourceName.toLowerCase();
        return selectedProviders.any((p) => source.contains(p.toLowerCase()));
      }).toList();

      return filtered.map((data) {
        return {
          'type': data.typeString,
          'value': data.value.toString(),
          'source': data.sourceName,
          'timestamp': data.dateFrom.toIso8601String(),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
