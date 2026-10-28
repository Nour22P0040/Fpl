import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:url_launcher/url_launcher.dart';

const Color fplPurple = Color(0xFF38003C);
const Color fplGreen = Color(0xFF00FF85);


String _proxied(String url) =>
    'https://wsrv.nl/?url=${Uri.encodeComponent(url)}&w=220&h=220&fit=cover&a=top&output=png';

/// Builds the list of image URLs to try, in order.
List<String> playerPhotoUrls(Map player, String webName) {
  final direct = <String>[];

  // 1. URL / filename from your JSON
  final dynamic raw = player['photo_url'] ?? player['image'] ?? player['photo'];
  final String? jsonImage = raw?.toString();

  if (jsonImage != null && jsonImage.isNotEmpty) {
    if (jsonImage.startsWith('http')) {
      direct.add(jsonImage);
    } else {
      final cleanCode = jsonImage.replaceAll('.jpg', '').replaceAll('.png', '');
      direct.addAll([
        'https://resources.premierleague.com/premierleague25/photos/players/110x140/$cleanCode.png',
        'https://resources.premierleague.com/premierleague/photos/players/110x140/p$cleanCode.png',
      ]);
    }
  }

  // 2. Fallback to player 'code'
  final code = player['code'];
  if (code != null) {
    direct.addAll([
      'https://resources.premierleague.com/premierleague25/photos/players/110x140/$code.png',
      'https://resources.premierleague.com/premierleague/photos/players/110x140/p$code.png',
    ]);
  }

  // Remove duplicates, keep order
  final unique = direct.toSet().toList();

  final urls = <String>[
    // Proxied versions first (work on web + mobile)
    ...unique.map(_proxied),
    // Then the direct ones
    ...unique,
    // Final failsafe: initials avatar
    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(webName)}'
        '&background=38003C&color=00FF85&bold=true&size=128',
  ];

  return urls;
}

/// Displays the first valid image URL, cascading down on errors.
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
    if (oldWidget.urls.join() != widget.urls.join()) {
      _index = 0;
    }
  }

  void _tryNext(int failedIndex) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Only advance if this is still the URL that failed
      if (mounted && _index == failedIndex) {
        setState(() => _index++);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget child;
    if (_index >= widget.urls.length) {
      child = const Icon(Icons.person, color: Colors.white);
    } else {
      final currentIndex = _index;
      child = Image.network(
        widget.urls[currentIndex],
        key: ValueKey(widget.urls[currentIndex]),
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        // Custom headers only on mobile/desktop (on web they trigger CORS preflight)
        headers: kIsWeb
            ? null
            : const {
          'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
          'Accept': 'image/png,image/*;q=0.8',
        },
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
          debugPrint('IMG FAIL [${widget.urls[currentIndex]}] -> $error');
          _tryNext(currentIndex);
          return const SizedBox.shrink();
        },
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[isDark ? 800 : 300],
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
          'https://raw.githubusercontent.com/Nour22P0040/Fpl/main/players.json';
      final response = await dio.get(url);

      dynamic responseData = response.data;

      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }

      if (responseData is Map) {
        return responseData['players'] ?? responseData['elements'] ?? [];
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
      'https://en.wikipedia.org/wiki/Special:Search?search=${Uri.encodeComponent(playerName)}',
    );

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : fplPurple;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[700];
    final iconColor = isDark ? fplGreen : fplPurple;
    final spinnerColor = isDark ? fplGreen : fplPurple;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('FPL Players'),
        backgroundColor: fplPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _playersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: spinnerColor),
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
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
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
              final String fullName =
              '${player['first_name'] ?? ''} ${player['second_name'] ?? ''}'
                  .trim();
              final String displayName =
              fullName.isNotEmpty ? fullName : (player['full_name'] ?? webName);
              final String team = player['team']?.toString() ?? 'Unknown Team';
              final String position =
                  player['pos'] ?? player['element_type']?.toString() ?? '';
              final String price = player['price']?.toString() ??
                  (player['now_cost'] != null
                      ? (player['now_cost'] / 10).toStringAsFixed(1)
                      : '0.0');

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: PlayerAvatar(urls: playerPhotoUrls(player, webName)),
                  title: Text(
                    webName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: titleColor,
                    ),
                  ),
                  subtitle: Text(
                    '$team | Pos: $position | £${price}m',
                    style: TextStyle(
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.language, color: iconColor),
                    tooltip: 'View on Wikipedia',
                    onPressed: () => _launchWikipedia(displayName),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added $webName to your squad!'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: subtitleColor,
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