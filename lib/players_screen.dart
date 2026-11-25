import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'calibration_store.dart';
import 'db_helper.dart';
import 'player.dart';
import 'players_view_model.dart';
import 'screens/profile_screen.dart';
import 'stadiums_screen.dart';

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


class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final PlayersViewModel viewModel = PlayersViewModel();

  // Shake to Surprise Me
  StreamSubscription<AccelerometerEvent>? _shakeSub;
  List<double> _offsets = [0, 0, 0];
  static const double _shakeThreshold = 8.0;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);
  bool _dialogOpen = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    viewModel.loadFavorites();
    _loadCachedPlayers(); // 1. show cached players right away
    _fetchPlayers(); //       2. fetch live players (wins when it arrives)

    _loadOffsets();
    _shakeSub = accelerometerEventStream().listen(
      _onAccelerometer,
      onError: (Object e) => debugPrint('Accelerometer unavailable: $e'),
    );
  }

  Future<void> _loadOffsets() async {
    final saved = await CalibrationStore.load();
    if (!mounted) return;
    _offsets = saved;
  }

  void _onAccelerometer(AccelerometerEvent e) {
    final x = e.x - _offsets[0];
    final y = e.y - _offsets[1];
    final z = e.z - _offsets[2];
    final force = sqrt(x * x + y * y + z * z);
    if ((force - 9.81).abs() <= _shakeThreshold) return; // not a shake

    final now = DateTime.now();
    if (now.difference(_lastShake) < const Duration(seconds: 1)) return;
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    if (_dialogOpen) return;
    _lastShake = now;

    _showSurprise();
  }

  /// Shows a random player; "Save to Bucket List" adds them to favorites.
  Future<void> _showSurprise() async {
    final players = viewModel.players;
    if (players.isEmpty) return;
    final p = players[_random.nextInt(players.length)];

    _dialogOpen = true;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Surprise!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayerAvatar(urls: playerPhotoUrls(p), size: 96),
            const SizedBox(height: 12),
            Text(
              p.webName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text('${p.team} | Pos: ${p.position} | £${p.price}m'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Shake again'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!viewModel.favoriteNames.contains(p.id)) {
                viewModel.toggleFavorite(p.id);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Save to Bucket List'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    // The user may have recalibrated in the Sensor Lab
    await _loadOffsets();
  }

  /// Reads players saved in SQLite. Only used if nothing is on screen yet,
  /// so a fast network result is never overwritten by older cached data.
  Future<void> _loadCachedPlayers() async {
    try {
      final cached = await DBHelper.getCachedPlayers();
      if (!mounted) return;
      if (viewModel.players.isEmpty && cached.isNotEmpty) {
        setState(() => viewModel.players = cached);
      }
    } catch (e) {
      debugPrint('Could not read cache: $e');
    }
  }

  /// Fetches live players, then refreshes the SQLite cache with them.
  Future<void> _fetchPlayers() async {
    final fresh = await viewModel.fetchPlayers();
    if (fresh != null) {
      try {
        await DBHelper.cachePlayers(fresh);
      } catch (e) {
        debugPrint('Could not write cache: $e');
      }
    } else if (viewModel.players.isEmpty) {
      // Offline and nothing cached yet: use the players bundled with the app
      await viewModel.loadBundledPlayers();
    }
  }

  @override
  void dispose() {
    _shakeSub?.cancel();
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

  Future<void> _openFavorites() async {
    await context.push('/favorites');
    // Favorites may have been removed there; reload them from storage
    await viewModel.loadFavorites();
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
            icon: const Icon(Icons.star),
            tooltip: 'My Bucket List',
            onPressed: _openFavorites,
          ),
          IconButton(
            icon: const Icon(Icons.groups),
            tooltip: 'FPL Buddies',
            onPressed: () => context.push('/buddies'),
          ),
          IconButton(
            icon: const Icon(Icons.stadium),
            tooltip: 'Stadiums Near You',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StadiumsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'My Profile',
            onPressed: _openProfile,
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