import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../db/app_database.dart';
import '../models/revenue_source.dart';

/// CRUD for custom revenue sources.
class SourceRepository {
  SourceRepository._();

  static final SourceRepository _instance = SourceRepository._();
  static SourceRepository get instance => _instance;

  Future<List<RevenueSource>> listSources() async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.query('custom_sources', orderBy: 'name ASC');
      return rows.map(RevenueSource.fromMap).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addSource(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Source name must not be empty');
    final db = await AppDatabase.database;
    await db.insert(
      'custom_sources',
      <String, Object?>{'name': trimmed},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
