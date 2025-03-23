import 'package:hive/hive.dart';

part 'daily_summary.g.dart';

@HiveType(typeId: 0)
class DailySummary extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  Duration timeSpentAtHome;

  @HiveField(2)
  Duration timeSpentAtOffice;

  @HiveField(3)
  Duration timeSpentTraveling;

  @HiveField(4)
  Duration totalTrackedTime;

  DailySummary({
    required this.date,
    required this.timeSpentAtHome,
    required this.timeSpentAtOffice,
    required this.timeSpentTraveling,
    required this.totalTrackedTime,
  });

  DailySummary copyWith({
    DateTime? date,
    Duration? timeSpentAtHome,
    Duration? timeSpentAtOffice,
    Duration? timeSpentTraveling,
    Duration? totalTrackedTime,
  }) {
    return DailySummary(
      date: date ?? this.date,
      timeSpentAtHome: timeSpentAtHome ?? this.timeSpentAtHome,
      timeSpentAtOffice: timeSpentAtOffice ?? this.timeSpentAtOffice,
      timeSpentTraveling: timeSpentTraveling ?? this.timeSpentTraveling,
      totalTrackedTime: totalTrackedTime ?? this.totalTrackedTime,
    );
  }

  String get formattedTimeSpentAtHome => _formatDuration(timeSpentAtHome);
  String get formattedTimeSpentAtOffice => _formatDuration(timeSpentAtOffice);
  String get formattedTimeSpentTraveling => _formatDuration(timeSpentTraveling);
  String get formattedTotalTime => _formatDuration(totalTrackedTime);

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours h $minutes m';
  }
}
