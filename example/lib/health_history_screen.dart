import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HealthHistoryScreen extends StatelessWidget {
  const HealthHistoryScreen({super.key});

  /// Fetch health data from a specific collection (steps, heart_rate, etc.)
  Stream<QuerySnapshot> getHealthDataStream(String collection) {
    return FirebaseFirestore.instance
        .collection(collection)
        .orderBy('synced_at', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final healthCollections = [
      'steps',
      'heart_rate',
      'blood_pressure',
      'blood_glucose',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health History'),
      ),
      body: ListView(
        children: healthCollections
            .map((collection) => HealthDataSection(
                  title: collection.replaceAll('_', ' ').toUpperCase(),
                  stream: getHealthDataStream(collection),
                ))
            .toList(),
      ),
    );
  }
}

class HealthDataSection extends StatelessWidget {
  final String title;
  final Stream<QuerySnapshot> stream;

  const HealthDataSection({
    super.key,
    required this.title,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(title),
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const ListTile(
                title: Text('No data available'),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(data.toString()),
                  subtitle: Text(data['synced_at'] ?? ''),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
