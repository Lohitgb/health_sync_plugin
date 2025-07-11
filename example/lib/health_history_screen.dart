import 'package:flutter/material.dart';
import 'package:health_sync_plugin/health_sync_plugin.dart';
import 'package:intl/intl.dart';

class HealthHistoryScreen extends StatefulWidget {
  const HealthHistoryScreen({super.key});

  @override
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  List<Map<String, dynamic>> _healthData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final data = await HealthHistoryFetcher().getHealthHistory();
    setState(() {
      _healthData = data;
      _loading = false;
    });
  }

  Widget _buildItem(Map<String, dynamic> data) {
    final date = DateTime.tryParse(data['timestamp'] ?? '');
    final formattedDate = date != null
        ? DateFormat('dd MMM, hh:mm a').format(date)
        : 'Unknown Time';

    return ListTile(
      title: Text('${data['type']}: ${data['value']}'),
      subtitle: Text('Source: ${data['source']}\nTime: $formattedDate'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health History'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _healthData.isEmpty
              ? const Center(child: Text('No health data available.'))
              : ListView.builder(
                  itemCount: _healthData.length,
                  itemBuilder: (_, index) => _buildItem(_healthData[index]),
                ),
    );
  }
}
