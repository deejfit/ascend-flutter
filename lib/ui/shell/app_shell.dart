import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import '../hunter_pass/hunter_pass_screen.dart';
import '../shared/spacing.dart';

/// Main shell: top segmented control (Dashboard | Hunter Pass) and content.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    HunterPassScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top bar: title + segmented control
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.lg, 0),
              child: Row(
                children: [
                  Text(
                    'Ascend',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                  const Spacer(),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Dashboard'), icon: Icon(Icons.dashboard_outlined)),
                      ButtonSegment(value: 1, label: Text('Hunter Pass'), icon: Icon(Icons.workspace_premium_outlined)),
                    ],
                    selected: {_selectedIndex},
                    onSelectionChanged: (Set<int> selected) {
                      setState(() => _selectedIndex = selected.first);
                    },
                    showSelectedIcon: false,
                  ),
                ],
              ),
            ),
            Spacing.gap24,
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      ),
    );
  }
}
