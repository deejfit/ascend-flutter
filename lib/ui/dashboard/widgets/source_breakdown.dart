import 'package:flutter/material.dart';

import '../../../data/models/revenue_entry.dart';
import '../../../utils/formatters.dart';
import '../../shared/spacing.dart';

/// Revenue by source for selected month: amounts with 2 decimals, sorted descending.
class SourceBreakdown extends StatelessWidget {
  const SourceBreakdown({
    super.key,
    required this.entries,
  });

  final List<RevenueEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final bySource = <String, double>{};
    for (final e in entries) {
      final isFreelance = e.source == 'Freelance';
      final amountIncl = isFreelance ? e.amount * 1.21 : e.amount;
      bySource[e.source] = (bySource[e.source] ?? 0) + amountIncl;
    }
    final sorted = bySource.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('By source', style: theme.headlineMedium),
        Spacing.gap16,
        if (sorted.isEmpty)
          Text('No entries this month.', style: theme.bodyLarge)
        else
          ...sorted.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(e.key, style: theme.bodyLarge),
                  ),
                  Text(
                    formatCurrencyTwoDecimals(e.value),
                    style: theme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
