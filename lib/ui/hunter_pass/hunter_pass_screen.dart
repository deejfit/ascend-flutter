import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/revenue_repository.dart';
import '../../domain/rank/rank_engine.dart';
import '../../utils/dates.dart';
import '../../utils/formatters.dart';
import '../shared/spacing.dart';

const String hunterName = 'David';

/// Hunter Pass tab: rank card. Rank = highest ever achieved (never drops).
class HunterPassScreen extends StatefulWidget {
  const HunterPassScreen({super.key});

  @override
  State<HunterPassScreen> createState() => _HunterPassScreenState();
}

class _HunterPassScreenState extends State<HunterPassScreen> {
  bool _loading = true;
  double _lifetimeTotal = 0;
  double _bestMonthTotal = 0;
  int _bestMonthYear = 0;
  int _bestMonthMonth = 0;
  DateTime? _firstEntryDate;
  RankResult? _currentRankResult;
  RankResult? _bestRankResult;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final now = DateTime.now();
      final rev = RevenueRepository.instance;
      final currentEntries =
          await rev.listEntriesForMonth(now.year, now.month);
      final allEntries = await rev.listAllEntries();
      final currentMonthTotal =
          currentEntries.fold<double>(0, (sum, e) => sum + e.amount);
      final lifetimeTotal = allEntries.fold<double>(0, (sum, e) => sum + e.amount);
      final byMonth = <(int year, int month), double>{};
      for (final e in allEntries) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.timestamp);
        final key = (d.year, d.month);
        byMonth[key] = (byMonth[key] ?? 0) + e.amount;
      }
      double bestMonthTotal = 0;
      int bestYear = now.year, bestMonth = now.month;
      for (final entry in byMonth.entries) {
        if (entry.value > bestMonthTotal) {
          bestMonthTotal = entry.value;
          bestYear = entry.key.$1;
          bestMonth = entry.key.$2;
        }
      }
      final firstEntryDate = allEntries.isEmpty
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              allEntries.map((e) => e.timestamp).reduce((a, b) => a < b ? a : b),
            );
      final currentRankResult = RankEngine.getRankProgress(currentMonthTotal);
      final bestRankResult = RankEngine.getRankProgress(bestMonthTotal);
      if (mounted) {
        setState(() {
          _lifetimeTotal = lifetimeTotal;
          _bestMonthTotal = bestMonthTotal;
          _bestMonthYear = bestYear;
          _bestMonthMonth = bestMonth;
          _firstEntryDate = firstEntryDate;
          _currentRankResult = currentRankResult;
          _bestRankResult = bestRankResult;
          _loading = false;
        });
      }
    } catch (e, st) {
      assert(() {
        // ignore: avoid_print
        print('HunterPass load error: $e\n$st');
        return true;
      }());
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Could not load data';
          _currentRankResult = RankEngine.getRankProgress(0);
          _bestRankResult = RankEngine.getRankProgress(0);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    // Show best rank ever so it never drops (je bent het hoogste wat je gehaald hebt)
    final rank = _bestRankResult;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(Spacing.xxl),
                  child: CircularProgressIndicator(),
                )
              : Container(
                  padding: const EdgeInsets.all(Spacing.lg),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_loadError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: Text(
                            _loadError!,
                            style: theme.bodySmall?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      Text(
                        'ASCEND – HUNTER PASS',
                        style: theme.labelLarge?.copyWith(
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Spacing.gap8,
                      Text(
                        hunterName,
                        style: theme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      Spacing.gap24,
                      Text('Your rank', style: theme.bodyLarge),
                      Text(
                        rank?.rank ?? 'F',
                        style: theme.displayMedium?.copyWith(
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
                            backgroundColor: colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        Spacing.gap8,
                        Text(
                          '${rank.progressPercent}% to ${rank.nextRank} · Remaining: ${formatCurrencyCompactNoDecimals(rank.remainingToNext)}',
                          style: theme.bodyMedium,
                        ),
                      ],
                      Spacing.gap24,
                      Text('Best month ever', style: theme.bodyLarge),
                      Text(
                        '${formatCurrencyCompactNoDecimals(_bestMonthTotal)} (${formatMonthLabel(_bestMonthYear, _bestMonthMonth)})',
                        style: theme.headlineSmall,
                      ),
                      Spacing.gap16,
                      Text('Lifetime revenue', style: theme.bodyLarge),
                      Text(
                        formatCurrencyCompactNoDecimals(_lifetimeTotal),
                        style: theme.headlineSmall,
                      ),
                      Spacing.gap16,
                      Text('First revenue entry', style: theme.bodyLarge),
                      Text(
                        _firstEntryDate != null
                            ? DateFormat.yMMMd().format(_firstEntryDate!)
                            : '—',
                        style: theme.headlineSmall,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
