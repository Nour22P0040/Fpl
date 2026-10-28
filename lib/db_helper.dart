import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'player.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'players.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => db.execute(
        'CREATE TABLE players('
            'id TEXT PRIMARY KEY, '
            'webName TEXT, '
            'fullName TEXT, '
            'team TEXT, '
            'position TEXT, '
            'price TEXT, '
            'code TEXT, '
            'photo TEXT)',
      ),
    );
  }

  /// Inserts every player; replace updates rows that already exist.
  static Future<void> cachePlayers(List<Player> players) async {
    final database = await db;
    final batch = database.batch();
    for (final p in players) {
      batch.insert(
        'players',
        p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Player>> getCachedPlayers() async {
    final database = await db;
    final rows = await database.query('players');
    return rows.map(Player.fromMap).toList();
  }
}