import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationDisplay extends StatelessWidget {
  final Position? position;

  const LocationDisplay({
    required this.position,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (position == null) {
      return const Text(
        'No location data available',
        style: TextStyle(fontSize: 14),
      );
    }

    return Column(
      children: [
        const Text(
          'Current Location:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Latitude: ${position!.latitude.toStringAsFixed(6)}',
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          'Longitude: ${position!.longitude.toStringAsFixed(6)}',
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          'Accuracy: ${position!.accuracy.toStringAsFixed(2)} meters',
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          'Timestamp: ${position!.timestamp}',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
