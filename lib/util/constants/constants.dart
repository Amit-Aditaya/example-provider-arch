class Constants {
  // Prevent instantiation
  Constants._();

  // Location tracking constants
  static const int locationUpdateIntervalSeconds = 5;
  static const int notificationIntervalMinutes = 15;

  // Notification channels
  static const String locationServiceChannelId = 'location_channel';
  static const String locationUpdatesChannelId = 'location_updates_channel';

  // Shared preferences keys
  static const String prefShowNotifications = 'showNotifications';
  static const String prefLatitude = 'latitude';
  static const String prefLongitude = 'longitude';
  static const String prefAccuracy = 'accuracy';
  static const String prefTimestamp = 'timestamp';
}
