import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db_helper.dart';
import 'player.dart';

class PlayersViewModel extends ChangeNotifier {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  static const _favKey = 'favorite_players';

  // State the screen reads
  List<Player> players = [];
  final Set<String> favoriteNames = {};
  bool isLoading = true;
  String? error;

  bool _disposed = false;

  /// Async work can finish after the screen is gone; notifying a disposed
  /// ChangeNotifier throws, so this guard keeps it safe.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Favorites -> cache -> network, in that order.
  Future<void> load() async {
    await loadFavorites();
    await loadCachedPlayers();
    await fetchPlayers();
  }

  Future<void> loadFavorites() async {
    try {
      final saved = await _prefs.getStringList(_favKey) ?? [];
      favoriteNames
        ..clear()
        ..addAll(saved);
      notifyListeners();
    } catch (e) {
      debugPrint('Could not load favorites: $e');
    }
  }

  /// Shows cached players, but only if nothing fresher has arrived yet.
  Future<void> loadCachedPlayers() async {
    try {
      final cached = await DBHelper.getCachedPlayers();
      if (players.isEmpty && cached.isNotEmpty) {
        players = cached;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Could not read cache: $e');
    }
  }

  Future<void> fetchPlayers() async {
    try {
      players = await _download();
      error = null;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return;
    }

    // A storage problem must not look like a network error
    try {
      await DBHelper.cachePlayers(players);
    } catch (e) {
      debugPrint('Could not write cache: $e');
    }
  }

  void toggleFavorite(String id) {
    if (!favoriteNames.remove(id)) {
      favoriteNames.add(id);
    }
    notifyListeners();
    _prefs.setStringList(_favKey, favoriteNames.toList());
  }

  Future<List<Player>> _download() async {
    try {
      final dio = Dio();
      const url =
          'https://raw.githubusercontent.com/Nour22P0040/Fpl/main/players.json';
      final response = await dio.get(url);

      dynamic data = response.data;
      if (data is String) {
        data = jsonDecode(data);
      }

      List raw = [];
      if (data is Map) {
        raw = data['players'] ?? data['elements'] ?? [];
      } else if (data is List) {
        raw = data;
      }

      return raw.whereType<Map>().map(Player.fromJson).toList();
    } catch (e) {
      throw Exception('Failed to load players: $e');
    }
  }
}