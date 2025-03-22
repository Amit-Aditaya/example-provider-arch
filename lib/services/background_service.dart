import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'location_service.dart';
import 'notification_service.dart';

class BackgroundService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Configure for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'location_channel',
      'Location Tracking Service',
      description: 'Background service for location tracking',
      importance: Importance.high,
    );

    await NotificationService.flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'location_channel',
        initialNotificationTitle: 'Location Tracking Service',
        initialNotificationContent: 'Initializing',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  // iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  // Main service function that runs in the background
  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    // For Android, ensure it's running as a foreground service
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Add a handler for updating settings
    bool showNotifications = true;
    service.on('updateSettings').listen((settings) {
      if (settings != null && settings['showNotifications'] != null) {
        showNotifications = settings['showNotifications'];
      }
    });

    // Start the location tracking loop
    await LocationService.startTracking(service, showNotifications);
  }
}
