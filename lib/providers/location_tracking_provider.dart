import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/adapters.dart';

import '../models/daily_summary.dart';

class LocationTrackingProvider extends ChangeNotifier {
  Box<DailySummary> get dailySummariesBox =>
      Hive.box<DailySummary>('dailySummaries');

  ValueNotifier<bool> isTracking = ValueNotifier<bool>(false);
  ValueNotifier<Position?> currentPosition = ValueNotifier<Position?>(null);
  ValueNotifier<String> statusMessage =
      ValueNotifier<String>('Location tracking is stopped');
  List<Position> locationHistory = [];
  Duration _timeAtHome = Duration.zero;

  static Position homeLocation = Position(
    latitude: 23.8149,
    longitude: 90.4336,
    timestamp: DateTime.now(),
    accuracy: 0,
    altitude: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
    altitudeAccuracy: 0,
    headingAccuracy: 0,
  );
  static const double homeRadius = 500;

  LocationTrackingProvider() {
    _checkServiceStatus();
    _listenForLocationUpdates();
  }

  void _listenForLocationUpdates() {
    FlutterBackgroundService().on('updateLocation').listen((event) {
      if (event != null) {
        final position = Position(
          longitude: event['longitude'] ?? 0.0,
          latitude: event['latitude'] ?? 0.0,
          timestamp: DateTime.parse(event['timestamp']),
          accuracy: event['accuracy'] ?? 0.0,
          altitude: event['altitude']?.toDouble() ?? 0.0,
          heading: event['heading']?.toDouble() ?? 0.0,
          speed: event['speed']?.toDouble() ?? 0.0,
          speedAccuracy: event['speedAccuracy']?.toDouble() ?? 0.0,
          altitudeAccuracy: event['altitudeAccuracy']?.toDouble() ?? 0.0,
          headingAccuracy: event['headingAccuracy']?.toDouble() ?? 0.0,
        );

        currentPosition.value = position;
        locationHistory.add(position);
        notifyListeners();
      }
    });
  }

  Future<void> startLocationTracking() async {
    locationHistory.clear();
    _timeAtHome = Duration.zero;
    final service = FlutterBackgroundService();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        statusMessage.value = 'Location permissions denied';
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      statusMessage.value = 'Location permissions permanently denied';
      notifyListeners();
      return;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      statusMessage.value = 'Location services are disabled';
      notifyListeners();
      return;
    }

    await service.startService();
    isTracking.value = true;
    statusMessage.value = 'Location tracking is active';
    notifyListeners();
  }

  Future<void> stopLocationTracking() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');

    _calculateTimeAtHome();

    isTracking.value = false;
    statusMessage.value =
        'Stopped. Time at home: ${_formatDuration(_timeAtHome)}';
    _saveDailySummary(_timeAtHome);
    notifyListeners();
  }

  void _calculateTimeAtHome() {
    _timeAtHome = Duration.zero;
    if (locationHistory.isEmpty) return;

    DateTime? entryTime;
    bool isInside = false;

    // Sort by timestamp and filter valid positions
    final sortedHistory = locationHistory
        .where((p) => p.timestamp != 0)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final position in sortedHistory) {
      final distance = Geolocator.distanceBetween(
        homeLocation.latitude,
        homeLocation.longitude,
        position.latitude,
        position.longitude,
      );

      if (distance <= homeRadius) {
        if (!isInside) {
          isInside = true;
          entryTime = position.timestamp;
        }
      } else {
        if (isInside) {
          isInside = false;
          if (entryTime != null) {
            _timeAtHome += position.timestamp.difference(entryTime);
          }
          entryTime = null;
        }
      }
    }

    if (isInside && entryTime != null) {
      _timeAtHome += DateTime.now().difference(entryTime);
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours h $minutes m';
  }

  Duration get timeAtHome => _timeAtHome;

  Future<void> _checkServiceStatus() async {
    final service = FlutterBackgroundService();
    isTracking.value = await service.isRunning();
    notifyListeners();
  }

  void _saveDailySummary(Duration timeAtHome) {
    final box = Hive.box<DailySummary>('dailySummaries');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final totalTrackedTime = locationHistory.isNotEmpty
        ? now.difference(locationHistory.first.timestamp)
        : Duration.zero;

    // Get existing or create new summary
    DailySummary summary = box.get(today.toIso8601String()) ??
        DailySummary(
          date: today,
          timeSpentAtHome: Duration.zero,
          totalTrackedTime: Duration.zero,
        );

    // Update values
    summary = summary.copyWith(
      timeSpentAtHome: summary.timeSpentAtHome + timeAtHome,
      totalTrackedTime: summary.totalTrackedTime + totalTrackedTime,
    );

    // Save using box.put() instead of summary.save()
    box.put(today.toIso8601String(), summary);
  }

  // Add helper method to get all summaries
  List<DailySummary> get allSummaries => dailySummariesBox.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
}
