import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'ui/shell/app_shell.dart';

/// Ascend – Hunter Rank Finance System.
class AscendApp extends StatelessWidget {
  const AscendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ascend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AppShell(),
    );
  }
}
