class Constants {
  // Prevent instantiation
  Constants._();

  // Location tracking constants
  static const int locationUpdateIntervalSeconds = 5;
  static const int notificationIntervalMinutes = 15;

  // Notification channels
  static const String locationServiceChannelId = 'location_channel';
  static const String locationUpdatesChannelId = 'location_updates_channel';
}
