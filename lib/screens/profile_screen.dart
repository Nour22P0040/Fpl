import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../colors.dart';
import '../sensor_lab_screen.dart';
import '../services/presence_service.dart';

/// Shows the signed-in manager's users/{uid} document, live:
/// a change in the Firebase console appears here without a refresh.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;
  bool loaded = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        profile = snapshot.data(); // null if the profile does not exist
        loaded = true;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _signOut() async {
    await PresenceService.stop();
    await FirebaseAuth.instance.signOut();
    // Back to the Start screen (go_router's version of popUntil(isFirst))
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : fplPurple;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: fplPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sensors),
            tooltip: 'Sensor Lab',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SensorLabScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: _buildBody(textColor),
    );
  }

  Widget _buildBody(Color textColor) {
    if (!loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final p = profile;
    if (p == null) {
      return Center(
        child: Text('No profile yet', style: TextStyle(color: textColor)),
      );
    }

    final style = TextStyle(fontSize: 18, color: textColor);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Name: ${p['name'] ?? '-'}', style: style),
        const SizedBox(height: 12),
        Text('Email: ${p['email'] ?? '-'}', style: style),
        const SizedBox(height: 12),
        Text('Phone: ${p['phone'] ?? '-'}', style: style),
        const SizedBox(height: 12),
        Text('FPL Team: ${p['team'] ?? '-'}', style: style),
      ],
    );
  }
}
