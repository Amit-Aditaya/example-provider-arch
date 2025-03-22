import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
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

              return ListView.builder(
                itemCount: summaries.length,
                itemBuilder: (context, index) {
                  final summary = summaries[index];
                  return ListTile(
                    title: Text(summary.formattedDate),
                    subtitle: Text('Home Time: ${summary.formattedTimeSpent}'),
                    trailing: Text('Total: ${summary.formattedTotalTime}'),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
