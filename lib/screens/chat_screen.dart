import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../colors.dart';
import '../data/chat_id.dart';
import '../data/last_seen.dart';

/// One-to-one chat stored in Firestore at chats/{chatId}/messages.
class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;

  const ChatScreen({super.key, required this.peerId, required this.peerName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  final String _myId = FirebaseAuth.instance.currentUser!.uid;

  late final CollectionReference<Map<String, dynamic>> _messages =
      FirebaseFirestore.instance
          .collection('chats')
          .doc(chatIdFor(_myId, widget.peerId))
          .collection('messages');

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Message cannot be empty';
    if (text.length > 500) return 'Message is too long (max 500 characters)';
    return null;
  }

  void _send() {
    if (!_formKey.currentState!.validate()) return;

    // add(), not set(): every message is a new document with its own id.
    // Not awaited: offline messages are queued by Firestore and sent later.
    _messages.add({
      'from': _myId,
      'text': _textController.text.trim(),
      'sentAt': FieldValue.serverTimestamp(),
    }).then((_) {}).catchError((e) {
      debugPrint('Could not send message: $e');
    });

    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: fplPurple,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.peerName),
            _PeerStatus(peerId: widget.peerId),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages(isDark)),
          _buildInput(isDark),
        ],
      ),
    );
  }

  Widget _buildMessages(bool isDark) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _messages
          .orderBy('sentAt', descending: true)
          .limit(50)
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
          return Center(
            child: Text(
              'Say hi to ${widget.peerName} 👋',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          );
        }
        return ListView.builder(
          reverse: true, // newest (first in the list) at the bottom
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data();
            return _MessageBubble(
              text: (data['text'] ?? '').toString(),
              isMine: data['from'] == _myId,
              pending: data['sentAt'] == null, // not yet on the server
              isDark: isDark,
            );
          },
        );
      },
    );
  }

  Widget _buildInput(bool isDark) {
    return SafeArea(
      top: false,
      child: Container(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _textController,
                  validator: _validate,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onFieldSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Message',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: isDark ? fplGreen : fplPurple),
                tooltip: 'Send',
                onPressed: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Right-aligned and tinted for my messages, left-aligned for the peer's.
class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final bool pending;
  final bool isDark;

  const _MessageBubble({
    required this.text,
    required this.isMine,
    required this.pending,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMine
        ? fplPurple
        : (isDark ? const Color(0xFF2C2C2C) : Colors.white);
    final fg = isMine ? Colors.white : (isDark ? Colors.white : Colors.black87);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(child: Text(text, style: TextStyle(color: fg))),
            if (isMine && pending) ...[
              const SizedBox(width: 6),
              const Icon(Icons.schedule, size: 12, color: Colors.white70),
            ],
          ],
        ),
      ),
    );
  }
}

/// The peer's live status from Realtime Database (same as Buddies).
class _PeerStatus extends StatelessWidget {
  final String peerId;

  const _PeerStatus({required this.peerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('status/$peerId').onValue,
      builder: (context, snapshot) {
        final value = snapshot.data?.snapshot.value;
        final status = value is Map ? value : null;
        final online = status?['state'] == 'online';
        final lastSeen = status?['lastSeen'];
        final text = online
            ? 'Online'
            : 'Last seen ${lastSeenText(lastSeen is int ? lastSeen : null)}';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: online ? fplGreen : Colors.grey,
              ),
            ),
            const SizedBox(width: 6),
            Text(text,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        );
      },
    );
  }
}
