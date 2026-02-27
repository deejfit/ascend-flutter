import '../db/app_database.dart';
import '../models/revenue_entry.dart';

/// CRUD for revenue entries. Enforces amount > 0.
class RevenueRepository {
  RevenueRepository._();

  static final RevenueRepository _instance = RevenueRepository._();
  static RevenueRepository get instance => _instance;

  Future<void> addEntry(RevenueEntry entry) async {
    if (entry.amount <= 0) throw ArgumentError('Amount must be > 0');
    final db = await AppDatabase.database;
    await db.insert(
      'revenue_entries',
      <String, Object?>{
        'amount': entry.amount,
        'source': entry.source,
        'note': entry.note,
        'timestamp': entry.timestamp,
      },
    );
  }

  Future<void> deleteEntry(int id) async {
    final db = await AppDatabase.database;
    await db.delete('revenue_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateEntry(RevenueEntry entry) async {
    if (entry.amount <= 0) throw ArgumentError('Amount must be > 0');
    final db = await AppDatabase.database;
    await db.update(
      'revenue_entries',
      <String, Object?>{
        'amount': entry.amount,
        'source': entry.source,
        'note': entry.note,
        'timestamp': entry.timestamp,
      },
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<List<RevenueEntry>> listEntriesForMonth(int year, int month) async {
    try {
      final start = DateTime(year, month, 1).millisecondsSinceEpoch;
      final end = DateTime(year, month + 1, 0, 23, 59, 59, 999).millisecondsSinceEpoch;
      final db = await AppDatabase.database;
      final rows = await db.query(
        'revenue_entries',
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [start, end],
        orderBy: 'timestamp ASC',
      );
      return rows.map(RevenueEntry.fromMap).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<RevenueEntry>> listEntriesForYear(int year) async {
    try {
      final start = DateTime(year, 1, 1).millisecondsSinceEpoch;
      final end = DateTime(year, 12, 31, 23, 59, 59, 999).millisecondsSinceEpoch;
      final db = await AppDatabase.database;
      final rows = await db.query(
        'revenue_entries',
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [start, end],
        orderBy: 'timestamp ASC',
      );
      return rows.map(RevenueEntry.fromMap).toList();
    } catch (_) {
      return [];
    }
  }

  /// All entries, ordered by timestamp ascending.
  Future<List<RevenueEntry>> listAllEntries() async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.query('revenue_entries', orderBy: 'timestamp ASC');
      return rows.map(RevenueEntry.fromMap).toList();
    } catch (_) {
      return [];
    }
  }

  /// Earliest entry date or null if no entries.
  Future<DateTime?> getFirstEntryDate() async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.rawQuery(
        'SELECT MIN(timestamp) AS min_ts FROM revenue_entries',
      );
      final min = rows.firstOrNull?['min_ts'];
      if (min == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(min as int);
    } catch (_) {
      return null;
    }
  }

  /// Distinct (year, month) pairs that have at least one entry. Newest first.
  Future<List<(int year, int month)>> getMonthsWithEntries() async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.rawQuery('''
        SELECT DISTINCT
          cast(strftime('%Y', timestamp/1000, 'unixepoch') as integer) AS y,
          cast(strftime('%m', timestamp/1000, 'unixepoch') as integer) AS m
        FROM revenue_entries
        ORDER BY y DESC, m DESC
      ''');
      return rows
          .map((r) => (r['y'] as int, r['m'] as int))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
