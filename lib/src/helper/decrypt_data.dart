import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_sync_plugin/health_sync_plugin.dart';

class HealthDecryptionService {
  /// Decrypts `daily_health_avg` collection
  static Future<List<Map<String, dynamic>>> getDecryptedDailyAverages() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('daily_health_avg')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();

    return Future.wait(snapshot.docs.map((doc) async {
      final data = doc['data'] as Map<String, dynamic>;
      final Map<String, dynamic> decrypted = {};

      for (var key in data.keys) {
        final encryptedEntry = data[key];
        decrypted[key] = await HealthSyncPlugin.decryptHealthValue(
          encryptedData: encryptedEntry['data'],
          iv: encryptedEntry['iv'],
        );
      }

      return {
        'timestamp': doc['timestamp'],
        'averages': decrypted,
      };
    }));
  }

  /// Decrypts `heart_rate` collection
  static Future<List<Map<String, dynamic>>> getDecryptedHeartRates() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('heart_rate')
        .orderBy('synced_at', descending: true)
        .limit(10)
        .get();

    return Future.wait(snapshot.docs.map((doc) async {
      final encrypted = doc['data'];
      final iv = doc['iv'];
      final decrypted = await HealthSyncPlugin.decryptHealthValue(
        encryptedData: encrypted,
        iv: iv,
      );

      return {
        'value': decrypted,
        'abnormal': doc['abnormal'],
        'synced_at': doc['synced_at'],
        'providers': doc['providers'],
      };
    }));
  }

  /// Decrypts `blood_pressure` collection
  static Future<List<Map<String, dynamic>>> getDecryptedBloodPressures() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('blood_pressure')
        .orderBy('synced_at', descending: true)
        .limit(10)
        .get();

    return Future.wait(snapshot.docs.map((doc) async {
      final systolic = doc['systolic'];
      final diastolic = doc['diastolic'];

      final decryptedSys = await HealthSyncPlugin.decryptHealthValue(
        encryptedData: systolic['value'],
        iv: systolic['iv'],
      );

      final decryptedDia = await HealthSyncPlugin.decryptHealthValue(
        encryptedData: diastolic['value'],
        iv: diastolic['iv'],
      );

      return {
        'systolic': decryptedSys,
        'diastolic': decryptedDia,
        'synced_at': doc['synced_at'],
        'providers': doc['providers'],
      };
    }));
  }
}
