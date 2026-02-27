import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'db_paths.dart';

const _version = 1;

/// App SQLite database singleton. Call [ensureInitialized] at startup.
class AppDatabase {
  AppDatabase._();

  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    return ensureInitialized();
  }

  /// Opens the DB, creates tables and seeds if needed. Call once before runApp.
  static Future<Database> ensureInitialized() async {
    if (_db != null) return _db!;
    sqfliteFfiInit();
    final dbPath = getDatabasePath();
    await File(dbPath).parent.create(recursive: true);
    _db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: _onCreate,
      ),
    );
    await _runOneOffMigrations(_db!);
    return _db!;
  }

  /// One-off data fixes. Each migration checks a meta_settings flag and runs at most once.
  static Future<void> _runOneOffMigrations(Database db) async {
    const key = 'migration_app_to_freelance';
    final rows = await db.query(
      'meta_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isNotEmpty) return;
    await db.execute(
      "UPDATE revenue_entries SET source = 'Freelance' WHERE source = 'App'",
    );
    await db.insert(
      'meta_settings',
      <String, Object?>{'key': key, 'value': '1'},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE revenue_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        source TEXT NOT NULL,
        note TEXT,
        timestamp INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE custom_sources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE meta_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await _seed(db);
  }

  static Future<void> _seed(Database db) async {
    const defaultSources = [
      'Freelance',
      'App',
      'Book',
      'Report',
      'Coaching',
      'Other',
    ];
    for (final name in defaultSources) {
      await db.insert(
        'custom_sources',
        <String, Object?>{'name': name},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await db.insert(
      'meta_settings',
      <String, Object?>{'key': 'monthly_target', 'value': '30000'},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
