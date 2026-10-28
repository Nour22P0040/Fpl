import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'player.dart';
import 'players_view_model.dart';

const Color fplPurple = Color(0xFF38003C);
const Color fplGreen = Color(0xFF00FF85);

String _proxied(String url) =>
    'https://wsrv.nl/?url=${Uri.encodeComponent(url)}&w=220&h=220&fit=cover&a=top&output=png';

/// Builds the list of image URLs to try, in order.
List<String> playerPhotoUrls(Player player) {
  final direct = <String>[];

  final jsonImage = player.photo;
  if (jsonImage.isNotEmpty) {
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

  if (player.code.isNotEmpty) {
    direct.addAll([
      'https://resources.premierleague.com/premierleague25/photos/players/110x140/${player.code}.png',
      'https://resources.premierleague.com/premierleague/photos/players/110x140/p${player.code}.png',
    ]);
  }

  final unique = direct.toSet().toList();

  return <String>[
    ...unique.map(_proxied),
    ...unique,
    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(player.webName)}'
        '&background=38003C&color=00FF85&bold=true&size=128',
  ];
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


class BucketListScreen extends StatelessWidget {
  final List<Player> savedPlayers;

  const BucketListScreen({super.key, required this.savedPlayers});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : fplPurple;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Bucket List'),
        backgroundColor: fplPurple,
        foregroundColor: Colors.white,
      ),
      body: savedPlayers.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No favorites yet.\nTap the heart on a player to save them.',
            textAlign: TextAlign.center,
            style: TextStyle(color: subtitleColor, fontSize: 16),
          ),
        ),
      )
          : ListView.builder(
        itemCount: savedPlayers.length,
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (context, index) {
          final p = savedPlayers[index];
          return Card(
            elevation: 2,
            margin:
            const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: PlayerAvatar(urls: playerPhotoUrls(p)),
              title: Text(
                p.webName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: titleColor,
                ),
              ),
              subtitle: Text(
                '${p.team} | Pos: ${p.position} | £${p.price}m',
                style: TextStyle(
                  color: subtitleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  // Created once; the screen only draws and forwards taps
  final PlayersViewModel viewModel = PlayersViewModel();

  @override
  void initState() {
    super.initState();
    viewModel.load();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
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

  void _openBucketList() {
    final saved = viewModel.players
        .where((p) => viewModel.favoriteNames.contains(p.id))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BucketListScreen(savedPlayers: saved),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('FPL Players'),
        backgroundColor: fplPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            tooltip: 'My Bucket List',
            onPressed: _openBucketList,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    final titleColor = isDark ? Colors.white : fplPurple;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[700];
    final iconColor = isDark ? fplGreen : fplPurple;
    final spinnerColor = isDark ? fplGreen : fplPurple;

    // Decide by the data first: show whatever we have, live or cached
    if (viewModel.players.isEmpty) {
      if (viewModel.isLoading) {
        return Center(child: CircularProgressIndicator(color: spinnerColor));
      }
      if (viewModel.error != null) {
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
                    'Error: ${viewModel.error}',
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return const Center(child: Text('No players found.'));
    }

    return Column(
      children: [
        if (viewModel.error != null)
          Container(
            width: double.infinity,
            color: Colors.orange.shade700,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: const Text(
              'Offline: showing saved players',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: viewModel.players.length,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              final p = viewModel.players[index];
              final bool isFavorite = viewModel.favoriteNames.contains(p.id);

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
                  leading: PlayerAvatar(urls: playerPhotoUrls(p)),
                  title: Text(
                    p.webName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: titleColor,
                    ),
                  ),
                  subtitle: Text(
                    '${p.team} | Pos: ${p.position} | £${p.price}m',
                    style: TextStyle(
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                        tooltip: isFavorite
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                        onPressed: () => viewModel.toggleFavorite(p.id),
                      ),
                      IconButton(
                        icon: Icon(Icons.language, color: iconColor),
                        tooltip: 'View on Wikipedia',
                        onPressed: () => _launchWikipedia(p.fullName),
                      ),
                    ],
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added ${p.webName} to your squad!'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: subtitleColor,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}