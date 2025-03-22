import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../providers/location_tracking_provider.dart';
import '../components/location_display.dart';
import 'summary_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationTrackingProvider>(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const SummaryScreen()));
        },
      ),
      appBar: AppBar(
        title: const Text('Background Location Tracker'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ValueListenableBuilder<String>(
              valueListenable: locationProvider.statusMessage,
              builder: (context, statusMessage, _) {
                return Text(
                  statusMessage,
                  style: const TextStyle(fontSize: 16),
                );
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => locationProvider.startLocationTracking(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Start Location Tracking',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            ElevatedButton(
              onPressed: () => locationProvider.stopLocationTracking(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Stop Location Tracking',
                style: TextStyle(fontSize: 16),
              ),
            ),

            // ValueListenableBuilder<String>(
            //   valueListenable: locationProvider.timeAtHome,
            //   builder: (context, timeAtHome, _) {
            //     return Text(
            //       timeAtHome,
            //       style: const TextStyle(fontSize: 16),
            //     );
            //   },
            // ),

            const SizedBox(height: 16),

            const SizedBox(height: 30),

            // Current location display
            ValueListenableBuilder<Position?>(
              valueListenable: locationProvider.currentPosition,
              builder: (context, position, _) {
                return LocationDisplay(position: position);
              },
            ),
          ],
        ),
      ),
    );
  }
}
