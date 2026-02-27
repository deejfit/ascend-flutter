import 'dart:io';

import 'package:path/path.dart' as path;

const _appName = 'Ascend';
const _dbFileName = 'ascend.db';

/// Application Support directory on macOS (~/Library/Application Support/Ascend).
String get _applicationSupportDir {
  final home = Platform.environment['HOME'];
  if (home != null && home.isNotEmpty) {
    return path.join(home, 'Library', 'Application Support', _appName);
  }
  // TODO: Fallback when HOME is not set (e.g. some sandbox); use current directory.
  return path.current;
}

/// Resolves a safe DB file path for macOS (Application Support, or current dir fallback).
String getDatabasePath([String? fileName]) {
  final dir = _applicationSupportDir;
  final file = fileName ?? _dbFileName;
  return path.join(dir, file);
}
