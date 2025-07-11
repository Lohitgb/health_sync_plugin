import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthHistoryFetcher {
  final Health _health = Health();

  Future<List<Map<String, dynamic>>> getHealthHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedProviders = prefs.getStringList('selected_providers') ?? [];

      // Read all supported types
      final types = <HealthDataType>[
        HealthDataType.HEART_RATE,
        HealthDataType.STEPS,
        HealthDataType.BLOOD_GLUCOSE,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      ];

      final permissions = List.filled(types.length, HealthDataAccess.READ);

      bool? hasPermission =
          await _health.hasPermissions(types, permissions: permissions);
      if (hasPermission != true) {
        hasPermission = await _health.requestAuthorization(
          types,
          permissions: permissions,
        );
      }

      if (hasPermission != true) return [];

      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 24));

      final rawData = await _health.getHealthDataFromTypes(
        startTime: startTime,
        endTime: now,
        types: types,
      );

      await _health.removeDuplicates(rawData);

      // Filter by selected providers (if any)
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
