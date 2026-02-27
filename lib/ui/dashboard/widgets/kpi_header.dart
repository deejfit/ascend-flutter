import 'package:flutter/material.dart';

import '../../shared/spacing.dart';
import '../../../domain/rank/rank_engine.dart';
import '../../../domain/metrics/metrics_engine.dart';
import '../../../utils/formatters.dart';

/// Top KPI block: current rank, progress to next, highest rank ever, lifetime, year total.
class KpiHeader extends StatelessWidget {
  const KpiHeader({
    super.key,
    this.currentRankResult,
    this.bestRankResult,
    this.metrics,
  });

  final RankResult? currentRankResult;
  final RankResult? bestRankResult;
  final MetricsSnapshot? metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final rank = currentRankResult;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rank?.rank ?? '—',
          style: theme.displayLarge?.copyWith(
            fontSize: 56,
            fontWeight: FontWeight.w200,
          ),
        ),
        if (rank != null) ...[
          Spacing.gap12,
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rank.progress0to1,
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          Spacing.gap8,
          Text(
            '${rank.progressPercent}% to ${rank.nextRank} · Remaining: ${formatCurrencyCompactNoDecimals(rank.remainingToNext)}',
            style: theme.bodyMedium,
          ),
        ],
        Spacing.gap24,
        Text('Highest rank ever', style: theme.bodyLarge),
        Text(
          bestRankResult?.rank ?? '—',
          style: theme.headlineSmall,
        ),
        Spacing.gap16,
        Text('Lifetime revenue', style: theme.bodyLarge),
        Text(
          metrics != null
              ? formatCurrencyCompactNoDecimals(metrics!.lifetimeTotal)
              : '—',
          style: theme.headlineMedium,
        ),
        Spacing.gap16,
        Text('Year total', style: theme.bodyLarge),
        Text(
          metrics != null
              ? formatCurrencyCompactNoDecimals(metrics!.yearTotal)
              : '—',
          style: theme.headlineMedium,
        ),
      ],
    );
  }
}
