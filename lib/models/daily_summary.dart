import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'daily_summary.g.dart';

@HiveType(typeId: 0)
class DailySummary extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  Duration timeSpentAtHome;

  @HiveField(2)
  Duration totalTrackedTime;

  DailySummary({
    required this.date,
    required this.timeSpentAtHome,
    required this.totalTrackedTime,
  });

  String get formattedDate => DateFormat('yyyy-MM-dd').format(date);
  String get formattedTimeSpent => _formatDuration(timeSpentAtHome);
  String get formattedTotalTime => _formatDuration(totalTrackedTime);

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  DailySummary copyWith({
    DateTime? date,
    Duration? timeSpentAtHome,
    Duration? totalTrackedTime,
  }) {
    return DailySummary(
      date: date ?? this.date,
      timeSpentAtHome: timeSpentAtHome ?? this.timeSpentAtHome,
      totalTrackedTime: totalTrackedTime ?? this.totalTrackedTime,
    );
  }
}
