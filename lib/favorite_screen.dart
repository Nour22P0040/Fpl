import 'package:flutter/material.dart';

import 'player.dart';
import 'players_screen.dart' show PlayerAvatar, playerPhotoUrls, fplPurple, fplGreen;
import 'players_view_model.dart';

/// Shows the saved (favorite) players.
/// Works fully offline: favorites come from SharedPreferences and player
/// details from the SQLite cache (or the bundled asset as a last resort).
class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final PlayersViewModel viewModel = PlayersViewModel();

  @override
  void initState() {
    super.initState();
    viewModel.loadOffline();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Bucket List'),
        backgroundColor: fplPurple,
        foregroundColor: Colors.white,
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

    if (viewModel.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: isDark ? fplGreen : fplPurple),
      );
    }

    final List<Player> saved = viewModel.favoritePlayers;

    if (saved.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No favorites yet.\nTap the heart on a player to save them.',
            textAlign: TextAlign.center,
            style: TextStyle(color: subtitleColor, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: saved.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final p = saved[index];
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
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              tooltip: 'Remove from favorites',
              onPressed: () => viewModel.toggleFavorite(p.id),
            ),
          ),
        );
      },
    );
  }
}
