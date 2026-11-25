import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'colors.dart';
import 'stadium.dart';

class StadiumsScreen extends StatefulWidget {
  const StadiumsScreen({super.key});

  @override
  State<StadiumsScreen> createState() => _StadiumsScreenState();
}

class _StadiumsScreenState extends State<StadiumsScreen> {
  Position? position;
  String? error;
  bool approximate = false;

  // Which "Open settings" button to offer (only for these two errors)
  bool _locationOff = false;
  bool _deniedForever = false;

  static const double _checkInRadius = 100; // metres

  @override
  void initState() {
    super.initState();
    _locate();
  }


  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {

      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  Future<void> _locate() async {
    setState(() {
      position = null;
      error = null;
      _locationOff = false;
      _deniedForever = false;
    });

    try {
      final pos = await _determinePosition();
      final accuracyStatus = await Geolocator.getLocationAccuracy();
      if (!mounted) return;
      setState(() {
        position = pos;
        approximate = accuracyStatus == LocationAccuracyStatus.reduced;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() => error =
          'Could not get a GPS fix in 15 seconds. Move near a window or outdoors and try again.');
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      setState(() {
        error = message;
        _locationOff = message == 'Location services are disabled.';
        _deniedForever = message.contains('permanently denied');
      });
    }
  }

  Future<void> _openSettings() async {
    if (_locationOff) {
      await Geolocator.openLocationSettings();
    } else if (_deniedForever) {
      await Geolocator.openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Stadiums Near You'),
        backgroundColor: fplPurple,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    final textColor = isDark ? Colors.white : fplPurple;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[700];

    if (position == null && error == null) {
      return Center(
        child: CircularProgressIndicator(color: isDark ? fplGreen : fplPurple),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _locate,
                child: const Text('Try again'),
              ),
              if (_locationOff || _deniedForever) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _openSettings,
                  child: const Text('Open settings'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final pos = position!;

    // Distance (metres) to every stadium, nearest first
    final sorted = stadiums
        .map((s) => (
              stadium: s,
              meters: Geolocator.distanceBetween(
                  pos.latitude, pos.longitude, s.lat, s.lng),
            ))
        .toList()
      ..sort((a, b) => a.meters.compareTo(b.meters));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Accuracy: ± ${pos.accuracy.round()} m',
          style: TextStyle(color: textColor, fontSize: 16),
        ),
        if (approximate)
          Card(
            color: Colors.orange[100],
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: const ListTile(
              leading: Icon(Icons.warning_amber, color: Colors.orange),
              title: Text('Approximate location'),
              subtitle: Text(
                  'Check In needs Precise location. Enable it in app settings.'),
            ),
          ),
        const SizedBox(height: 8),
        for (final item in sorted)
          Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(Icons.stadium,
                  color: isDark ? fplGreen : fplPurple),
              title: Text(
                item.stadium.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              subtitle: Text(
                '${(item.meters / 1000).toStringAsFixed(2)} km',
                style: TextStyle(color: subtitleColor),
              ),
              trailing: ElevatedButton(
                onPressed: !approximate && item.meters <= _checkInRadius
                    ? () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Checked in at ${item.stadium.name}!'),
                          ),
                        )
                    : null,
                child: const Text('Check In'),
              ),
            ),
          ),
      ],
    );
  }
}
