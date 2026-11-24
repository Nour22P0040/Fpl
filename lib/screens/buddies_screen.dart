import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../colors.dart';
import '../data/last_seen.dart';

/// Every manager (from Firestore) with a live online status
/// (from Realtime Database), joined in the UI.
class BuddiesScreen extends StatelessWidget {
  const BuddiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('FPL Buddies'),
        backgroundColor: fplPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No managers yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, i) => BuddyTile(
              userId: docs[i].id,
              data: docs[i].data(),
            ),
          );
        },
      ),
    );
  }
}

/// One row: name, team, and a live status dot from status/{userId}.
class BuddyTile extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> data;

  const BuddyTile({super.key, required this.userId, required this.data});

  @override
  Widget build(BuildContext context) {
    final isMe = userId == FirebaseAuth.instance.currentUser?.uid;
    final name = '${data['name'] ?? 'Unknown'}${isMe ? ' (you)' : ''}';

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('status/$userId').onValue,
      builder: (context, snapshot) {
        final value = snapshot.data?.snapshot.value;
        final status = value is Map ? value : null; // missing node -> null
        final online = status?['state'] == 'online';
        final lastSeen = status?['lastSeen'];

        final statusText = online
            ? 'Online'
            : 'Last seen ${lastSeenText(lastSeen is int ? lastSeen : null)}';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: fplPurple,
              child: Text(
                (data['name'] ?? '?').toString().characters.first.toUpperCase(),
                style: const TextStyle(color: fplGreen),
              ),
            ),
            title: Text(name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Team: ${data['team'] ?? '-'}\n$statusText'),
            isThreeLine: true,
            // Tap someone else's row to chat with them
            onTap: isMe
                ? null
                : () => context.push('/chat', extra: {
                      'peerId': userId,
                      'peerName': (data['name'] ?? 'Manager').toString(),
                    }),
            trailing: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: online ? Colors.green : Colors.grey,
              ),
            ),
          ),
        );
      },
    );
  }
}
