import 'package:flutter/material.dart';

import '../../shared/spacing.dart';
import '../../../domain/rank/rank_engine.dart';
import '../../../domain/metrics/metrics_engine.dart';
import '../../../utils/formatters.dart';

/// Top KPI block: current rank, progress to next, highest rank ever, lifetime, year total.
/// All totals are shown incl. VAT, with a smaller excl. VAT hint.
class KpiHeader extends StatelessWidget {
  const KpiHeader({
    super.key,
    this.currentRankResult,
    this.bestRankResult,
    this.metrics,
    this.monthlyTarget,
  });

  final RankResult? currentRankResult;
  final RankResult? bestRankResult;
  final MetricsSnapshot? metrics;
  final int? monthlyTarget;

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
        if (metrics != null && monthlyTarget != null) ...[
          Text('Goal progress (incl. VAT)', style: theme.bodyLarge),
          Text(
            '${formatCurrencyCompactNoDecimals(metrics!.monthTotal)} / ${formatCurrencyCompactNoDecimals(monthlyTarget!.toDouble())}'
            ' (${_goalPercent(metrics!.monthTotal, monthlyTarget!).toStringAsFixed(0)}%)',
            style: theme.headlineSmall,
          ),
          Spacing.gap16,
        ],
        Text('Highest rank ever', style: theme.bodyLarge),
        Text(
          bestRankResult?.rank ?? '—',
          style: theme.headlineSmall,
        ),
        Spacing.gap16,
        Text('Lifetime revenue (incl. VAT)', style: theme.bodyLarge),
        Text(
          metrics != null
              ? formatCurrencyCompactNoDecimals(metrics!.lifetimeTotal)
              : '—',
          style: theme.headlineMedium,
        ),
        if (metrics != null) ...[
          Spacing.gap8,
          Text(
            'Excl. VAT: ${formatCurrencyCompactNoDecimals(metrics!.lifetimeTotalExcl)}',
            style: theme.bodySmall,
          ),
        ],
        Spacing.gap16,
        Text('Year total (incl. VAT)', style: theme.bodyLarge),
        Text(
          metrics != null
              ? formatCurrencyCompactNoDecimals(metrics!.yearTotal)
              : '—',
          style: theme.headlineMedium,
        ),
        if (metrics != null) ...[
          Spacing.gap8,
          Text(
            'Excl. VAT: ${formatCurrencyCompactNoDecimals(metrics!.yearTotalExcl)}',
            style: theme.bodySmall,
          ),
        ],
      ],
    );
  }

  double _goalPercent(double value, int target) {
    if (target <= 0) return 0;
    final pct = (value / target) * 100;
    if (pct.isNaN || pct.isInfinite) return 0;
    return pct.clamp(0, 999);
  }
}
