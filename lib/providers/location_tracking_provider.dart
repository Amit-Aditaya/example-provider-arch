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
  Duration _timeAtOffice = Duration.zero;
  Duration _timeTraveling = Duration.zero;

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

  static Position officeLocation = Position(
    latitude: 23.7945, // Example coordinates
    longitude: 90.4142,
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
  static const double officeRadius = 500;

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
    _timeAtOffice = Duration.zero;
    _timeTraveling = Duration.zero;
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

    _calculateTimeSpent();

    isTracking.value = false;
    statusMessage.value = 'Tracking Stopped.';
    // 'Home: ${_formatDuration(_timeAtHome)}, '
    // 'Office: ${_formatDuration(_timeAtOffice)}, '
    // 'Traveling: ${_formatDuration(_timeTraveling)}';

    _saveDailySummary();
    notifyListeners();
  }

  void _calculateTimeSpent() {
    _timeAtHome = Duration.zero;
    _timeAtOffice = Duration.zero;
    _timeTraveling = Duration.zero;

    if (locationHistory.isEmpty) return;

    final sortedHistory = locationHistory.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    String currentZone = 'traveling';
    DateTime? zoneEntryTime;

    for (final position in sortedHistory) {
      final newZone = _determineZone(position);

      if (zoneEntryTime != null && currentZone != newZone) {
        final duration = position.timestamp.difference(zoneEntryTime);
        _addDuration(currentZone, duration);
      }

      currentZone = newZone;
      zoneEntryTime = position.timestamp;
    }

    // Add remaining time from last position to now
    if (zoneEntryTime != null) {
      final duration = DateTime.now().difference(zoneEntryTime);
      _addDuration(currentZone, duration);
    }
  }

  String _determineZone(Position position) {
    final homeDistance = Geolocator.distanceBetween(
      homeLocation.latitude,
      homeLocation.longitude,
      position.latitude,
      position.longitude,
    );

    if (homeDistance <= homeRadius) return 'home';

    final officeDistance = Geolocator.distanceBetween(
      officeLocation.latitude,
      officeLocation.longitude,
      position.latitude,
      position.longitude,
    );

    if (officeDistance <= officeRadius) return 'office';

    return 'traveling';
  }

  void _addDuration(String zone, Duration duration) {
    switch (zone) {
      case 'home':
        _timeAtHome += duration;
        break;
      case 'office':
        _timeAtOffice += duration;
        break;
      case 'traveling':
        _timeTraveling += duration;
        break;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours h $minutes m';
  }

  Future<void> _checkServiceStatus() async {
    final service = FlutterBackgroundService();
    isTracking.value = await service.isRunning();
    notifyListeners();
  }

  void _saveDailySummary() {
    final box = Hive.box<DailySummary>('dailySummaries');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final totalTrackedTime = locationHistory.isNotEmpty
        ? now.difference(locationHistory.first.timestamp)
        : Duration.zero;

    DailySummary summary = box.get(today.toIso8601String()) ??
        DailySummary(
          date: today,
          timeSpentAtHome: Duration.zero,
          timeSpentAtOffice: Duration.zero,
          timeSpentTraveling: Duration.zero,
          totalTrackedTime: Duration.zero,
        );

    summary = summary.copyWith(
      timeSpentAtHome: summary.timeSpentAtHome + _timeAtHome,
      timeSpentAtOffice: summary.timeSpentAtOffice + _timeAtOffice,
      timeSpentTraveling: summary.timeSpentTraveling + _timeTraveling,
      totalTrackedTime: summary.totalTrackedTime + totalTrackedTime,
    );

    box.put(today.toIso8601String(), summary);
  }

  List<DailySummary> get allSummaries => dailySummariesBox.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
}
