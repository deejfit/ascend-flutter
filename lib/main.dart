import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/db/app_database.dart';
import 'data/repositories/settings_repository.dart';
import 'domain/rank/rank_engine.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('nl_NL', null);
    RankEngine.runSanityChecksInDebug();
    try {
      await AppDatabase.ensureInitialized();
      await SettingsRepository.instance.ensureDefaults();
    } catch (e, st) {
      assert(() {
        // ignore: avoid_print
        print('DB init error: $e\n$st');
        return true;
      }());
      // Continue so app starts; screens will show empty/error state
    }
    runApp(const AscendApp());
  }, (error, stack) {
    assert(() {
      // ignore: avoid_print
      print('Uncaught: $error\n$stack');
      return true;
    }());
  });
}
