import 'package:shared_preferences/shared_preferences.dart';

/// Saves the accelerometer calibration offsets so they survive restarts.
class CalibrationStore {
  static final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static Future<void> save(List<double> offsets) async {
    await _prefs.setDouble('offset_x', offsets[0]);
    await _prefs.setDouble('offset_y', offsets[1]);
    await _prefs.setDouble('offset_z', offsets[2]);
  }

  /// Returns [x, y, z]; zeros if nothing has been saved yet.
  static Future<List<double>> load() async {
    final x = await _prefs.getDouble('offset_x') ?? 0.0;
    final y = await _prefs.getDouble('offset_y') ?? 0.0;
    final z = await _prefs.getDouble('offset_z') ?? 0.0;
    return [x, y, z];
  }
}
