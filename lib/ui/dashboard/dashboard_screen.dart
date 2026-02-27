import 'package:flutter/material.dart';

import '../../data/models/revenue_entry.dart';
import '../../data/repositories/revenue_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/metrics/metrics_engine.dart';
import '../../domain/rank/rank_engine.dart';
import '../../utils/dates.dart';
import '../../utils/formatters.dart';
import '../shared/add_entry_fab.dart';
import '../shared/spacing.dart';
import 'widgets/kpi_header.dart';
import 'widgets/month_entries_list.dart';
import 'widgets/month_selector.dart';
import 'widgets/revenue_chart.dart';
import 'widgets/source_breakdown.dart';

/// Controller for dashboard: selected month, loaded entries, computed metrics and rank.
class DashboardController extends ChangeNotifier {
  DashboardController() {
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  int _selectedYear = 0;
  int _selectedMonth = 0;
  bool _loading = true;
  List<RevenueEntry> _selectedMonthEntries = [];
  List<RevenueEntry> _prevMonthEntries = [];
  List<RevenueEntry> _allEntries = [];
  int _monthlyTarget = 30000;
  MetricsSnapshot? _metrics;
  RankResult? _currentRankResult;
  RankResult? _bestRankResult;

  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  bool get loading => _loading;
  List<RevenueEntry> get selectedMonthEntries => _selectedMonthEntries;
  List<RevenueEntry> get prevMonthEntries => _prevMonthEntries;
  int get monthlyTarget => _monthlyTarget;
  MetricsSnapshot? get metrics => _metrics;
  RankResult? get currentRankResult => _currentRankResult;
  RankResult? get bestRankResult => _bestRankResult;

  Future<void> setMonth(int year, int month) async {
    if (_selectedYear == year && _selectedMonth == month) return;
    _selectedYear = year;
    _selectedMonth = month;
    notifyListeners();
    await reload();
  }

  Future<void> reload() async {
    _loading = true;
    notifyListeners();
    try {
      final rev = RevenueRepository.instance;
      final prev = previousMonth(_selectedYear, _selectedMonth);
      final target = await SettingsRepository.instance.getMonthlyTarget();
      _monthlyTarget = target;
      final selected = await rev.listEntriesForMonth(_selectedYear, _selectedMonth);
      final prevList = await rev.listEntriesForMonth(prev.$1, prev.$2);
      final all = await rev.listAllEntries();
      _selectedMonthEntries = selected;
      _prevMonthEntries = prevList;
      _allEntries = all;
      _metrics = MetricsEngine.compute(
        selectedMonthEntries: _selectedMonthEntries,
        prevMonthEntries: _prevMonthEntries,
        allEntries: _allEntries,
        selectedYear: _selectedYear,
        selectedMonth: _selectedMonth,
      );
      _currentRankResult = RankEngine.getRankProgress(_metrics!.monthTotal);
      _bestRankResult = RankEngine.getRankProgress(_metrics!.bestMonthTotal);
    } catch (_) {
      // Keep previous state on error
    }
    _loading = false;
    notifyListeners();
  }
}

/// Dashboard tab: KPIs, month selector, chart placeholder, source breakdown.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController _controller = DashboardController();

  @override
  void initState() {
    super.initState();
    _controller.reload();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final m = _controller.metrics;
        final theme = Theme.of(context).textTheme;
        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KpiHeader(
                currentRankResult: _controller.currentRankResult,
                bestRankResult: _controller.bestRankResult,
                metrics: m,
                monthlyTarget: _controller.monthlyTarget,
              ),
              Spacing.gap32,
              MonthSelector(
                selectedYear: _controller.selectedYear,
                selectedMonth: _controller.selectedMonth,
                onMonthChanged: (y, mo) => _controller.setMonth(y, mo),
              ),
              Spacing.gap32,
              RevenueChart(
                selectedMonthEntries: _controller.selectedMonthEntries,
                prevMonthEntries: _controller.prevMonthEntries,
                monthlyTarget: _controller.monthlyTarget,
                selectedYear: _controller.selectedYear,
                selectedMonth: _controller.selectedMonth,
              ),
              Spacing.gap32,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current month total (incl. VAT)', style: theme.bodyLarge),
                        if (m != null)
                          Text(
                            formatCurrencyCompactNoDecimals(m.monthTotal),
                            style: theme.headlineMedium,
                          ),
                        if (m != null) ...[
                          Spacing.gap8,
                          Text(
                            'Excl. VAT: ${formatCurrencyCompactNoDecimals(m.monthTotalExcl)}',
                            style: theme.bodySmall,
                          ),
                        ],
                        Spacing.gap16,
                        Text(
                          'Growth vs previous',
                          style: theme.bodyLarge,
                        ),
                        if (m != null)
                          Text(
                            m.prevMonthTotal == 0
                                ? 'Awakening'
                                : '${m.growthPercent!.toStringAsFixed(1)}%',
                            style: theme.headlineSmall,
                          )
                        else
                          Text('—', style: theme.bodyMedium),
                        Spacing.gap16,
                        Text('Best month ever', style: theme.bodyLarge),
                        if (m != null)
                          Text(
                            '${formatCurrencyCompactNoDecimals(m.bestMonthTotal)} (${formatMonthLabel(m.bestMonthYear, m.bestMonthMonth)})',
                            style: theme.headlineSmall,
                          ),
                        if (m != null && m.daysLeftInMonth > 0) ...[
                          Spacing.gap16,
                          Text('Days left in month', style: theme.bodyLarge),
                          Text('${m.daysLeftInMonth}', style: theme.headlineSmall),
                        ],
                        if (m != null &&
                            m.daysLeftInMonth > 0 &&
                            m.requiredPerDayToNextRank > 0) ...[
                          Spacing.gap16,
                          Text('Required per day to next rank',
                              style: theme.bodyLarge),
                          Text(
                            formatCurrencyCompactNoDecimals(
                                m.requiredPerDayToNextRank),
                            style: theme.headlineSmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.lg),
                  Expanded(
                    child: SourceBreakdown(entries: _controller.selectedMonthEntries),
                  ),
                ],
              ),
              Spacing.gap32,
              MonthEntriesList(
                entries: _controller.selectedMonthEntries,
                selectedYear: _controller.selectedYear,
                selectedMonth: _controller.selectedMonth,
                onReload: () => _controller.reload(),
              ),
              if (_controller.loading)
                const Padding(
                  padding: EdgeInsets.only(top: Spacing.sm),
                  child: LinearProgressIndicator(),
                ),
            ],
            ),
          ),
          floatingActionButton: AddEntryFab(
            selectedYear: _controller.selectedYear,
            selectedMonth: _controller.selectedMonth,
            onReload: () => _controller.reload(),
          ),
        );
      },
    );
  }
}
