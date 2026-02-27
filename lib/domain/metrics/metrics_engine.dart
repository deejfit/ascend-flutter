import '../../data/models/revenue_entry.dart';
import '../../utils/dates.dart';
import '../rank/rank_engine.dart';

/// Result of metrics for a selected month: totals, growth, best month, rank pacing.
class MetricsSnapshot {
  const MetricsSnapshot({
    required this.monthTotal,
    required this.prevMonthTotal,
    required this.growthPercent,
    required this.lifetimeTotal,
    required this.yearTotal,
    required this.bestMonthTotal,
    required this.bestMonthYear,
    required this.bestMonthMonth,
    required this.daysInSelectedMonth,
    required this.daysLeftInMonth,
    required this.requiredPerDayToNextRank,
    this.firstEntryDate,
  });

  final double monthTotal;
  final double prevMonthTotal;
  /// Null if prevMonthTotal == 0.
  final double? growthPercent;
  final double lifetimeTotal;
  final double yearTotal;
  final double bestMonthTotal;
  final int bestMonthYear;
  final int bestMonthMonth;
  final int daysInSelectedMonth;
  /// 0 if selected month is not the current month.
  final int daysLeftInMonth;
  /// 0 if selected month is not current or daysLeft <= 0.
  final double requiredPerDayToNextRank;
  final DateTime? firstEntryDate;
}

/// Computes aggregates from entry lists. No UI.
class MetricsEngine {
  MetricsEngine._();

  static double _sum(List<RevenueEntry> entries) {
    return entries.fold(0.0, (s, e) => s + e.amount);
  }

  /// Builds a snapshot from the given entry lists and selected month.
  static MetricsSnapshot compute({
    required List<RevenueEntry> selectedMonthEntries,
    required List<RevenueEntry> prevMonthEntries,
    required List<RevenueEntry> allEntries,
    required int selectedYear,
    required int selectedMonth,
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    final monthTotal = _sum(selectedMonthEntries);
    final prevMonthTotal = _sum(prevMonthEntries);
    final growthPercent = prevMonthTotal == 0
        ? null
        : (monthTotal - prevMonthTotal) / prevMonthTotal * 100;

    final lifetimeTotal = _sum(allEntries);

    final selectedYearEntries = allEntries
        .where((e) => DateTime.fromMillisecondsSinceEpoch(e.timestamp).year == selectedYear)
        .toList();
    final yearTotal = _sum(selectedYearEntries);

    final byMonth = <(int year, int month), double>{};
    for (final e in allEntries) {
      final d = DateTime.fromMillisecondsSinceEpoch(e.timestamp);
      final key = (d.year, d.month);
      byMonth[key] = (byMonth[key] ?? 0) + e.amount;
    }
    double bestMonthTotal = 0;
    int bestMonthYear = selectedYear;
    int bestMonthMonth = selectedMonth;
    for (final entry in byMonth.entries) {
      if (entry.value > bestMonthTotal) {
        bestMonthTotal = entry.value;
        bestMonthYear = entry.key.$1;
        bestMonthMonth = entry.key.$2;
      }
    }

    final daysInSelectedMonth = daysInMonth(selectedYear, selectedMonth);
    final isCurrentMonth =
        selectedYear == now.year && selectedMonth == now.month;
    final daysLeftInMonth = isCurrentMonth
        ? (daysInSelectedMonth - now.day).clamp(0, daysInSelectedMonth)
        : 0;

    final rankResult = RankEngine.getRankProgress(monthTotal);
    final remainingToNext = rankResult.remainingToNext;
    final requiredPerDayToNextRank = (!isCurrentMonth || daysLeftInMonth <= 0)
        ? 0.0
        : remainingToNext / daysLeftInMonth.clamp(1, daysInSelectedMonth);

    final firstEntryDate = allEntries.isEmpty
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            allEntries.map((e) => e.timestamp).reduce((a, b) => a < b ? a : b),
          );

    return MetricsSnapshot(
      monthTotal: monthTotal,
      prevMonthTotal: prevMonthTotal,
      growthPercent: growthPercent,
      lifetimeTotal: lifetimeTotal,
      yearTotal: yearTotal,
      bestMonthTotal: bestMonthTotal,
      bestMonthYear: bestMonthYear,
      bestMonthMonth: bestMonthMonth,
      daysInSelectedMonth: daysInSelectedMonth,
      daysLeftInMonth: daysLeftInMonth,
      requiredPerDayToNextRank: requiredPerDayToNextRank,
      firstEntryDate: firstEntryDate,
    );
  }
}
