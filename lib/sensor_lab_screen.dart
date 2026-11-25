import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'calibration_store.dart';
import 'colors.dart';

/// Live accelerometer + gyroscope readings, with calibration.
class SensorLabScreen extends StatefulWidget {
  const SensorLabScreen({super.key});

  @override
  State<SensorLabScreen> createState() => _SensorLabScreenState();
}

class _SensorLabScreenState extends State<SensorLabScreen> {
  List<double> offsets = [0, 0, 0];
  bool _calibrating = false;

  late final Stream<AccelerometerEvent> _accelStream;
  late final Stream<GyroscopeEvent> _gyroStream;

  @override
  void initState() {
    super.initState();
    _accelStream = accelerometerEventStream();
    _gyroStream = gyroscopeEventStream();
    _loadOffsets();
  }

  Future<void> _loadOffsets() async {
    final saved = await CalibrationStore.load();
    if (!mounted) return;
    setState(() => offsets = saved);
  }

  /// Phone must lie flat: x and y should read 0, z should read 9.81 (gravity).
  Future<void> _calibrate() async {
    setState(() => _calibrating = true);
    try {
      final samples = await _accelStream
          .take(50)
          .timeout(const Duration(seconds: 5))
          .toList();

      double sx = 0, sy = 0, sz = 0;
      for (final e in samples) {
        sx += e.x;
        sy += e.y;
        sz += e.z;
      }
      final n = samples.length;
      final avgX = sx / n, avgY = sy / n, avgZ = sz / n;

      final newOffsets = [avgX - 0, avgY - 0, avgZ - 9.81];
      await CalibrationStore.save(newOffsets);
      if (!mounted) return;
      setState(() => offsets = newOffsets);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sensors calibrated')),
      );
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calibration timed out: no accelerometer data'),
        ),
      );
    } finally {
      if (mounted) setState(() => _calibrating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : fplPurple;
    final titleStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
    final valueStyle = TextStyle(fontSize: 18, color: textColor);
    final hintStyle = TextStyle(
      fontSize: 14,
      color: isDark ? Colors.grey[400] : Colors.grey[700],
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Sensor Lab'),
        backgroundColor: fplPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Accelerometer', style: titleStyle),
            const SizedBox(height: 8),
            StreamBuilder<AccelerometerEvent>(
              stream: _accelStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Accelerometer unavailable', style: valueStyle);
                }
                if (!snapshot.hasData) {
                  return Text(
                    'Waiting for accelerometer data...',
                    style: valueStyle,
                  );
                }
                final e = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('X: ${(e.x - offsets[0]).toStringAsFixed(2)}',
                        style: valueStyle),
                    Text('Y: ${(e.y - offsets[1]).toStringAsFixed(2)}',
                        style: valueStyle),
                    Text('Z: ${(e.z - offsets[2]).toStringAsFixed(2)}',
                        style: valueStyle),
                    const SizedBox(height: 4),
                    Text(
                      'Offsets: '
                      '${offsets[0].toStringAsFixed(2)}, '
                      '${offsets[1].toStringAsFixed(2)}, '
                      '${offsets[2].toStringAsFixed(2)}',
                      style: hintStyle,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Text('Gyroscope', style: titleStyle),
            const SizedBox(height: 8),
            StreamBuilder<GyroscopeEvent>(
              stream: _gyroStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Gyroscope unavailable', style: valueStyle);
                }
                if (!snapshot.hasData) {
                  return Text('Waiting for gyroscope data...',
                      style: valueStyle);
                }
                final e = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('X: ${e.x.toStringAsFixed(2)}', style: valueStyle),
                    Text('Y: ${e.y.toStringAsFixed(2)}', style: valueStyle),
                    Text('Z: ${e.z.toStringAsFixed(2)}', style: valueStyle),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: fplPurple,
                  foregroundColor: Colors.white,
                ),
                icon: _calibrating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.tune),
                label: Text(
                    _calibrating ? 'Calibrating...' : 'Calibrate Sensors'),
                onPressed: _calibrating ? null : _calibrate,
              ),
            ),
            const SizedBox(height: 8),
            Text('Lay the phone flat on a table before calibrating.',
                style: hintStyle),
          ],
        ),
      ),
    );
  }
}
