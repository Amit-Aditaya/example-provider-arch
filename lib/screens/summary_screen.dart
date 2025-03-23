import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/daily_summary.dart';
import '../providers/location_tracking_provider.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracking History')),
      body: Consumer<LocationTrackingProvider>(
        builder: (context, provider, _) {
          return ValueListenableBuilder<Box<DailySummary>>(
            valueListenable:
                Hive.box<DailySummary>('dailySummaries').listenable(),
            builder: (context, box, _) {
              final summaries = box.values.toList()
                ..sort((a, b) => b.date.compareTo(a.date));

              if (summaries.isEmpty) {
                return const Center(
                  child: Text('No tracking data available'),
                );
              }

              return ListView.builder(
                itemCount: summaries.length,
                itemBuilder: (context, index) {
                  final summary = summaries[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        DateFormat('yyyy-MM-dd – kk:mm').format(summary.date),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _buildTimeRow(
                              '🏠 Home:', summary.formattedTimeSpentAtHome),
                          _buildTimeRow(
                              '🏢 Office:', summary.formattedTimeSpentAtOffice),
                          _buildTimeRow('🚗 Traveling:',
                              summary.formattedTimeSpentTraveling),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Total Tracked',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(summary.formattedTotalTime),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTimeRow(String label, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Text(time),
        ],
      ),
    );
  }
}
