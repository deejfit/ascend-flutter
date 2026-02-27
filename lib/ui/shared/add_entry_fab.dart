import 'package:flutter/material.dart';

import 'add_entry_modal.dart';

/// FAB to open add-revenue-entry modal. Pass selected month and reload callback.
class AddEntryFab extends StatelessWidget {
  const AddEntryFab({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onReload,
  });

  final int selectedYear;
  final int selectedMonth;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => AddEntryModal(
          selectedYear: selectedYear,
          selectedMonth: selectedMonth,
          onSaved: onReload,
        ),
      ),
      child: const Icon(Icons.add),
    );
  }
}
