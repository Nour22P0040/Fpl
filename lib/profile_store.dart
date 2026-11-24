import 'package:shared_preferences/shared_preferences.dart';

/// Keeps each account's name/team on the device (keyed by uid) so the app
/// can open the Welcome screen without internet.
class ProfileStore {
  static final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static Future<void> save(String uid, String name, String team) async {
    await _prefs.setString('profile_name_$uid', name);
    await _prefs.setString('profile_team_$uid', team);
  }

  /// Returns null if this account has no profile saved on this device.
  static Future<Map<String, String>?> load(String uid) async {
    final name = await _prefs.getString('profile_name_$uid');
    final team = await _prefs.getString('profile_team_$uid');
    if (name == null) return null;
    return {'name': name, 'team': team ?? 'My Team'};
  }
}
