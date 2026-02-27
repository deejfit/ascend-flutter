import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../db/app_database.dart';

/// Settings (e.g. monthly target). Ensures defaults on startup.
class SettingsRepository {
  SettingsRepository._();

  static final SettingsRepository _instance = SettingsRepository._();
  static SettingsRepository get instance => _instance;

  static const int defaultMonthlyTarget = 30000;
  static const _keyMonthlyTarget = 'monthly_target';

  Future<int> getMonthlyTarget() async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.query(
        'meta_settings',
        where: 'key = ?',
        whereArgs: [_keyMonthlyTarget],
      );
      final value = rows.firstOrNull?['value'] as String?;
      if (value == null) return defaultMonthlyTarget;
      return int.tryParse(value) ?? defaultMonthlyTarget;
    } catch (_) {
      return defaultMonthlyTarget;
    }
  }

  /// Ensures meta_settings has monthly_target. Safe to call on every startup.
  Future<void> ensureDefaults() async {
    try {
      final db = await AppDatabase.database;
      await db.insert(
        'meta_settings',
        <String, Object?>{'key': _keyMonthlyTarget, 'value': '$defaultMonthlyTarget'},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (_) {
      // DB may not be initialized; ignore
    }
  }
}
