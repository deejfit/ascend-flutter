import '../../data/models/revenue_entry.dart';
import '../../utils/dates.dart';
import '../rank/rank_engine.dart';

const _vatRate = 0.21;

/// Result of metrics for a selected month: totals, growth, best month, rank pacing.
/// All *Total fields are inclusive of VAT. Excluding-VAT variants are provided as *_Excl.
class MetricsSnapshot {
  const MetricsSnapshot({
    required this.monthTotal, // incl. VAT
    required this.monthTotalExcl,
    required this.prevMonthTotal, // incl. VAT
    required this.growthPercent,
    required this.lifetimeTotal, // incl. VAT
    required this.lifetimeTotalExcl,
    required this.yearTotal, // incl. VAT
    required this.yearTotalExcl,
    required this.bestMonthTotal, // incl. VAT
    required this.bestMonthTotalExcl,
    required this.bestMonthYear,
    required this.bestMonthMonth,
    required this.daysInSelectedMonth,
    required this.daysLeftInMonth,
    required this.requiredPerDayToNextRank,
    this.firstEntryDate,
  });

  /// Selected month total (incl. VAT).
  final double monthTotal;

  /// Selected month total (excl. VAT).
  final double monthTotalExcl;

  /// Previous month total (incl. VAT).
  final double prevMonthTotal;

  /// Null if prevMonthTotal == 0.
  final double? growthPercent;

  /// Lifetime total (incl. VAT).
  final double lifetimeTotal;

  /// Lifetime total (excl. VAT).
  final double lifetimeTotalExcl;

  /// Selected year total (incl. VAT).
  final double yearTotal;

  /// Selected year total (excl. VAT).
  final double yearTotalExcl;

  /// Best month total (incl. VAT).
  final double bestMonthTotal;

  /// Best month total (excl. VAT).
  final double bestMonthTotalExcl;

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

  static double _amountIncl(RevenueEntry e) {
    return e.source == 'Freelance' ? e.amount * (1 + _vatRate) : e.amount;
  }

  static double _amountExcl(RevenueEntry e) {
    return e.source == 'Freelance' ? e.amount : e.amount / (1 + _vatRate);
  }

  static (double incl, double excl) _sumInclExcl(List<RevenueEntry> entries) {
    double incl = 0;
    double excl = 0;
    for (final e in entries) {
      incl += _amountIncl(e);
      excl += _amountExcl(e);
    }
    return (incl, excl);
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

    final (monthTotal, monthTotalExcl) = _sumInclExcl(selectedMonthEntries);
    final (prevMonthTotal, _) = _sumInclExcl(prevMonthEntries);

    final growthPercent = prevMonthTotal == 0
        ? null
        : (monthTotal - prevMonthTotal) / prevMonthTotal * 100;

    final (lifetimeTotal, lifetimeTotalExcl) = _sumInclExcl(allEntries);

    final selectedYearEntries = allEntries
        .where((e) =>
            DateTime.fromMillisecondsSinceEpoch(e.timestamp).year ==
            selectedYear)
        .toList();
    final (yearTotal, yearTotalExcl) = _sumInclExcl(selectedYearEntries);

    // Best month based on inclusive totals.
    final byMonthIncl = <(int year, int month), double>{};
    final byMonthExcl = <(int year, int month), double>{};
    for (final e in allEntries) {
      final d = DateTime.fromMillisecondsSinceEpoch(e.timestamp);
      final key = (d.year, d.month);
      byMonthIncl[key] = (byMonthIncl[key] ?? 0) + _amountIncl(e);
      byMonthExcl[key] = (byMonthExcl[key] ?? 0) + _amountExcl(e);
    }
    double bestMonthTotal = 0;
    double bestMonthTotalExcl = 0;
    int bestMonthYear = selectedYear;
    int bestMonthMonth = selectedMonth;
    for (final entry in byMonthIncl.entries) {
      if (entry.value > bestMonthTotal) {
        bestMonthTotal = entry.value;
        bestMonthTotalExcl = byMonthExcl[entry.key] ?? 0;
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
            allEntries
                .map((e) => e.timestamp)
                .reduce((a, b) => a < b ? a : b),
          );

    return MetricsSnapshot(
      monthTotal: monthTotal,
      monthTotalExcl: monthTotalExcl,
      prevMonthTotal: prevMonthTotal,
      growthPercent: growthPercent,
      lifetimeTotal: lifetimeTotal,
      lifetimeTotalExcl: lifetimeTotalExcl,
      yearTotal: yearTotal,
      yearTotalExcl: yearTotalExcl,
      bestMonthTotal: bestMonthTotal,
      bestMonthTotalExcl: bestMonthTotalExcl,
      bestMonthYear: bestMonthYear,
      bestMonthMonth: bestMonthMonth,
      daysInSelectedMonth: daysInSelectedMonth,
      daysLeftInMonth: daysLeftInMonth,
      requiredPerDayToNextRank: requiredPerDayToNextRank,
      firstEntryDate: firstEntryDate,
    );
  }
}
