import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

const Color fplPurple = Color(0xFF38003C);
const Color fplGreen = Color(0xFF00FF85);

/// Builds the ordered list of image URLs to try for a player.
/// 1) `photo_url` from your JSON (if you add it)  -> best, you control it server-side
/// 2) URLs built from the FPL `code` (NOT the `id`) -> the photo files are named by code
/// 3) generated initials avatar                    -> last resort, always works
List<String> playerPhotoUrls(Map player, String webName) {
  final urls = <String>[];

  final direct = player['photo_url'];
  if (direct is String && direct.isNotEmpty) urls.add(direct);

  final code = player['code'];
  if (code != null) {
    urls.addAll([
      'https://resources.premierleague.com/premierleague25/photos/players/110x140/$code.png',
      'https://resources.premierleague.com/premierleague26/photos/players/110x140/$code.png',
      'https://resources.premierleague.com/premierleague/photos/players/110x140/p$code.png',
    ]);
  }

  urls.add(
    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(webName)}'
        '&background=38003C&color=00FF85&bold=true&size=128',
  );
  return urls;
}

/// Shows the first URL that loads successfully, moving down the list on errors.
class PlayerAvatar extends StatefulWidget {
  final List<String> urls;
  final double size;

  const PlayerAvatar({super.key, required this.urls, this.size = 56});

  @override
  State<PlayerAvatar> createState() => _PlayerAvatarState();
}

class _PlayerAvatarState extends State<PlayerAvatar> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant PlayerAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urls.join() != widget.urls.join()) _index = 0;
  }

  void _tryNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _index++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    Widget child;
    if (_index >= widget.urls.length) {
      child = const Icon(Icons.person, color: Colors.white);
    } else {
      child = Image.network(
        widget.urls[_index],
        key: ValueKey(widget.urls[_index]),
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter, // keeps the face in frame for 110x140 photos
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: fplPurple),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          _tryNext();
          return const SizedBox.shrink();
        },
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
        border: Border.all(color: fplGreen, width: 2),
      ),
      child: ClipOval(child: child),
    );
  }
}

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  late Future<List<dynamic>> _playersFuture;

  @override
  void initState() {
    super.initState();
    _playersFuture = fetchPlayers();
  }

  Future<List<dynamic>> fetchPlayers() async {
    try {
      final dio = Dio();

      const url =
          'https://raw.githubusercontent.com/gauravshrestha1/fplextract/main/fpl-data/players.json';
      final response = await dio.get(url);

      dynamic responseData = response.data;

      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }

      if (responseData is Map) {
        return responseData['players'] ?? [];
      }

      if (responseData is List) {
        return responseData;
      }

      return [];
    } catch (e) {
      throw Exception('Failed to load players: $e');
    }
  }

  Future<void> _launchWikipedia(String playerName) async {
    final url = Uri.parse(
        'https://en.wikipedia.org/wiki/Special:Search?search=${Uri.encodeComponent(playerName)}');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Wikipedia')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('FPL Players'),
        backgroundColor: fplPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _playersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: fplPurple),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No players found.'),
            );
          }

          final playersList = snapshot.data!;

          return ListView.builder(
            itemCount: playersList.length,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              final player = playersList[index] as Map;

              final String webName = player['web_name'] ?? 'Unknown';
              final String fullName = player['full_name'] ?? webName;
              final String team = player['team'] ?? 'Unknown Team';
              final String position = player['pos'] ?? '';
              final String price = player['price']?.toString() ?? '0.0';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: PlayerAvatar(urls: playerPhotoUrls(player, webName)),
                  title: Text(
                    webName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: fplPurple,
                    ),
                  ),
                  subtitle: Text(
                    '$team | Pos: $position | £${price}m',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.language, color: fplPurple),
                    tooltip: 'View on Wikipedia',
                    onPressed: () => _launchWikipedia(fullName),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added $webName to your squad!'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: fplPurple,
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
