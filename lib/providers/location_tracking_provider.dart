import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationTrackingProvider extends ChangeNotifier {
  ValueNotifier<bool> isTracking = ValueNotifier<bool>(false);
  ValueNotifier<Position?> currentPosition = ValueNotifier<Position?>(null);
  ValueNotifier<String> statusMessage =
      ValueNotifier<String>('Location tracking is stopped');
  ValueNotifier<bool> showNotifications = ValueNotifier<bool>(true);

  LocationTrackingProvider() {
    _checkServiceStatus();
    _listenForLocationUpdates();
    _loadSettings();
  }

  void _listenForLocationUpdates() {
    FlutterBackgroundService().on('updateLocation').listen((event) {
      if (event != null) {
        final position = Position(
          longitude: event['longitude'],
          latitude: event['latitude'],
          timestamp: DateTime.parse(event['timestamp']),
          accuracy: event['accuracy'],
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        currentPosition.value = position;
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    showNotifications.value = prefs.getBool('showNotifications') ?? true;
  }

  Future<void> toggleNotifications() async {
    showNotifications.value = !showNotifications.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showNotifications', showNotifications.value);

    // Update the background service with the new setting
    final service = FlutterBackgroundService();
    service.invoke('updateSettings', {
      'showNotifications': showNotifications.value,
    });

    notifyListeners();
  }

  Future<void> _checkServiceStatus() async {
    final service = FlutterBackgroundService();
    final bool running = await service.isRunning();
    isTracking.value = running;
    statusMessage.value = running
        ? 'Location tracking is active'
        : 'Location tracking is stopped';
    notifyListeners();
  }

  Future<void> startLocationTracking() async {
    final service = FlutterBackgroundService();

    // Check and request permissions
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

    // Check if location services are enabled
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      statusMessage.value = 'Location services are disabled';
      notifyListeners();
      return;
    }

    // Start the background service
    await service.startService();

    // Pass current notification settings to the service
    service.invoke('updateSettings', {
      'showNotifications': showNotifications.value,
    });

    // Update local state
    isTracking.value = true;
    statusMessage.value = 'Location tracking is active';
    notifyListeners();
  }

  Future<void> stopLocationTracking() async {
    final service = FlutterBackgroundService();

    // Stop the background service
    service.invoke('stopService');

    // Update local state
    isTracking.value = false;
    statusMessage.value = 'Location tracking is stopped';
    notifyListeners();
  }
}
