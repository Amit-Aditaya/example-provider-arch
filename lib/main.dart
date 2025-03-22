import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/daily_summary.dart';
import 'providers/location_tracking_provider.dart';
import 'screens/home_screen.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'util/adapters/duration_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService.initialize();

  // Initialize background service
  await BackgroundService.initialize();

  await Hive.initFlutter();
  Hive.registerAdapter(DurationAdapter());
  Hive.registerAdapter(DailySummaryAdapter());
  await Hive.openBox<DailySummary>('dailySummaries');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationTrackingProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Background Location Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
