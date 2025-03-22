import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import '../util/constants/constants.dart';
import 'notification_service.dart';

class LocationService {
  static Future<bool> checkPermissions() async {
    // Check and request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  static Future<void> startTracking(
    ServiceInstance service,
    bool showNotifications,
  ) async {
    // Verify permissions
    if (!await checkPermissions()) {
      return;
    }

    // Track the last notification time to avoid too frequent notifications
    DateTime lastNotificationTime = DateTime.now();

    // Continuously track location in the background
    while (true) {
      try {
        // Get current position
        final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Update notification with latest location
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'Location Tracking Active',
            content: 'Lat: ${position.latitude.toStringAsFixed(4)}, ' +
                'Lng: ${position.longitude.toStringAsFixed(4)}',
          );
        }

        // Send a local notification if enabled and if enough time has passed
        final now = DateTime.now();
        if (showNotifications &&
            now.difference(lastNotificationTime).inSeconds >=
                Constants.notificationIntervalMinutes) {
          await NotificationService.showLocationUpdateNotification(
            position.latitude,
            position.longitude,
          );
          lastNotificationTime = now;
        }

        // Broadcast location to app
        service.invoke('updateLocation', {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
        });

        // Wait before getting location again
        await Future.delayed(
          const Duration(seconds: Constants.locationUpdateIntervalSeconds),
        );
      } catch (e) {
        print('Error tracking location: $e');
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }
}
