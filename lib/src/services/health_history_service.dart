import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthHistoryFetcher {
  final Health _health = Health();

  Future<List<Map<String, dynamic>>> getHealthHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedProviders = prefs.getStringList('selected_providers') ?? [];
    final selectedHealthTypes =
        prefs.getStringList('selected_health_types') ?? [];

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

    final permissions = List.filled(types.length, HealthDataAccess.READ);

    bool? hasPermission =
        await _health.hasPermissions(types, permissions: permissions);
    if (hasPermission != true) {
      hasPermission =
          await _health.requestAuthorization(types, permissions: permissions);
    }

    if (hasPermission != true) {
      return [];
    }

    final now = DateTime.now();
    final startTime = now.subtract(const Duration(hours: 24));

    final healthData = await _health.getHealthDataFromTypes(
      startTime: startTime,
      endTime: now,
      types: types,
    );

    await _health.removeDuplicates(healthData);

    final List<HealthDataPoint> filtered = healthData.where((data) {
      final source = data.sourceName.toLowerCase();
      if (selectedProviders.isEmpty) return true;
      return selectedProviders.any((p) => source.contains(p.toLowerCase()));
    }).toList();

    final List<Map<String, dynamic>> mapped = filtered.map((data) {
      return {
        'type': data.typeString,
        'value': data.value.toString(),
        'source': data.sourceName,
        'timestamp': data.dateFrom.toIso8601String(),
      };
    }).toList();

    return mapped;
  }
}
