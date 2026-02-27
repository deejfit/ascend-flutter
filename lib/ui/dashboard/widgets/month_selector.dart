import 'package:flutter/material.dart';

import '../../../../data/repositories/revenue_repository.dart';
import '../../../../utils/dates.dart';

/// Minimal dropdown to choose a month. Options: last 12 months + current year months + months with entries (deduped).
class MonthSelector extends StatefulWidget {
  const MonthSelector({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  final int selectedYear;
  final int selectedMonth;
  final void Function(int year, int month) onMonthChanged;

  @override
  State<MonthSelector> createState() => _MonthSelectorState();
}

class _MonthSelectorState extends State<MonthSelector> {
  List<(int year, int month)> _options = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    final Set<(int, int)> set = {};

    // Last 12 months
    int y = currentYear, m = currentMonth;
    for (int i = 0; i < 12; i++) {
      set.add((y, m));
      final prev = previousMonth(y, m);
      y = prev.$1;
      m = prev.$2;
    }

    // All months of current year (so user can pick Jan, Feb, etc. even if empty)
    for (int month = 1; month <= 12; month++) {
      set.add((currentYear, month));
    }

    // Months that have any entries (placeholder-safe: if repo fails, we still have the above)
    try {
      final withEntries = await RevenueRepository.instance.getMonthsWithEntries();
      for (final p in withEntries) {
        set.add(p);
      }
    } catch (_) {
      // Placeholder: keep list from last 12 + current year only
    }

    final list = set.toList()
      ..sort((a, b) {
        if (a.$1 != b.$1) return b.$1.compareTo(a.$1);
        return b.$2.compareTo(a.$2);
      });

    if (mounted) {
      setState(() {
        _options = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Text(
        formatMonthLabel(widget.selectedYear, widget.selectedMonth),
        style: Theme.of(context).textTheme.headlineMedium,
      );
    }

    final selectedLabel = formatMonthLabel(widget.selectedYear, widget.selectedMonth);
    final isSelectedInList = _options.any((p) =>
        p.$1 == widget.selectedYear && p.$2 == widget.selectedMonth);
    final combined = isSelectedInList
        ? _options
        : [(widget.selectedYear, widget.selectedMonth), ..._options];
    final options = combined.toSet().toList()
      ..sort((a, b) {
        if (a.$1 != b.$1) return b.$1.compareTo(a.$1);
        return b.$2.compareTo(a.$2);
      });

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedLabel,
        isExpanded: false,
        items: options
            .map((p) => DropdownMenuItem<String>(
                  value: formatMonthLabel(p.$1, p.$2),
                  child: Text(formatMonthLabel(p.$1, p.$2)),
                ))
            .toList(),
        onChanged: (String? label) {
          if (label == null) return;
          final item = options.firstWhere(
            (p) => formatMonthLabel(p.$1, p.$2) == label,
            orElse: () => (widget.selectedYear, widget.selectedMonth),
          );
          widget.onMonthChanged(item.$1, item.$2);
        },
      ),
    );
  }
}
