import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Online / offline presence in Realtime Database at status/{uid}.
/// Not a widget: a background service driven by sign-in and the app lifecycle.
class PresenceService {
  static StreamSubscription<DatabaseEvent>? _connectedSub;

  /// status/{uid} of the signed-in manager, or null when signed out.
  static DatabaseReference? get _ref {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? null : FirebaseDatabase.instance.ref('status/$uid');
  }

  /// ServerValue.timestamp = the server's clock, not the phone's.
  static Map<String, Object> _status(String state) =>
      {'state': state, 'lastSeen': ServerValue.timestamp};

  /// Listens to .info/connected. Every time we (re)connect:
  /// FIRST register the offline write on the server, THEN write online.
  static void start() {
    final ref = _ref;
    if (ref == null) return;

    _connectedSub?.cancel();
    _connectedSub = FirebaseDatabase.instance
        .ref('.info/connected')
        .onValue
        .listen((event) async {
      if (event.snapshot.value != true) return;
      try {
        await ref.onDisconnect().set(_status('offline'));
        await ref.set(_status('online'));
      } catch (e) {
        debugPrint('Presence error: $e');
      }
    });
  }

  static Future<void> setOnline() async {
    await _ref?.set(_status('online')).catchError((e) {
      debugPrint('Could not set online: $e');
    });
  }

  static Future<void> setOffline() async {
    await _ref?.set(_status('offline')).catchError((e) {
      debugPrint('Could not set offline: $e');
    });
  }

  /// Called before sign-out: stop listening, cancel the pending
  /// onDisconnect and write offline while we still have a user.
  static Future<void> stop() async {
    await _connectedSub?.cancel();
    _connectedSub = null;

    final ref = _ref;
    if (ref == null) return;
    try {
      // Timeout so sign-out never hangs when there is no internet
      await Future.wait([
        ref.onDisconnect().cancel(),
        ref.set(_status('offline')),
      ]).timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Could not stop presence: $e');
    }
  }
}
