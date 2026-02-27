import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../data/models/revenue_entry.dart';
import '../../../../utils/dates.dart';
import '../../shared/spacing.dart';

/// Revenue line chart: ideal pace, current month cumulative, previous month ghost.
class RevenueChart extends StatelessWidget {
  const RevenueChart({
    super.key,
    required this.selectedMonthEntries,
    required this.prevMonthEntries,
    required this.monthlyTarget,
    required this.selectedYear,
    required this.selectedMonth,
  });

  final List<RevenueEntry> selectedMonthEntries;
  final List<RevenueEntry> prevMonthEntries;
  final int monthlyTarget;
  final int selectedYear;
  final int selectedMonth;

  /// Cumulative by day (1-based). Map dayIndex -> cumulative sum; day 0 = 0.
  static List<double> _cumulativeByDay(
    List<RevenueEntry> entries,
    int year,
    int month,
  ) {
    final days = daysInMonth(year, month);
    final daily = List<double>.filled(days + 1, 0);
    for (final e in entries) {
      final d = DateTime.fromMillisecondsSinceEpoch(e.timestamp);
      if (d.year != year || d.month != month) continue;
      final day = d.day.clamp(1, days);
      daily[day] += e.amount;
    }
    final cumulative = List<double>.filled(days + 1, 0);
    for (var i = 1; i <= days; i++) {
      cumulative[i] = cumulative[i - 1] + daily[i];
    }
    return cumulative;
  }

  /// Spots for cumulative line: (0,0) then (day/days, cumulative[day]) for day 1..days.
  static List<FlSpot> _cumulativeSpots(List<double> cumulative, int days) {
    if (days <= 0) return [const FlSpot(0, 0)];
    final spots = <FlSpot>[const FlSpot(0, 0)];
    for (var day = 1; day <= days; day++) {
      final x = day / days;
      spots.add(FlSpot(x, cumulative[day]));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final daysCur = daysInMonth(selectedYear, selectedMonth);
    final prev = previousMonth(selectedYear, selectedMonth);
    final daysPrev = daysInMonth(prev.$1, prev.$2);

    final cumCur = _cumulativeByDay(selectedMonthEntries, selectedYear, selectedMonth);
    final cumPrev = _cumulativeByDay(prevMonthEntries, prev.$1, prev.$2);

    final totalCur = cumCur.isNotEmpty ? cumCur.last : 0.0;
    final totalPrev = cumPrev.isNotEmpty ? cumPrev.last : 0.0;
    final target = monthlyTarget.toDouble();
    final maxY = (_max(target, totalCur, totalPrev) * 1.1).clamp(1000.0, double.infinity);

    final idealSpots = [const FlSpot(0, 0), FlSpot(1, target)];
    final currentSpots = _cumulativeSpots(cumCur, daysCur);
    final prevSpots = _cumulativeSpots(cumPrev, daysPrev);

    final lineBars = [
      // Ideal: y = target * x
      LineChartBarData(
        spots: idealSpots,
        isCurved: false,
        color: colorScheme.outline.withValues(alpha: 0.7),
        barWidth: 1.5,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
      // Current month
      LineChartBarData(
        spots: currentSpots,
        isCurved: true,
        color: colorScheme.primary,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
      // Previous month ghost
      LineChartBarData(
        spots: prevSpots,
        isCurved: true,
        color: colorScheme.onSurface.withValues(alpha: 0.35),
        barWidth: 1.5,
        isStrokeCapRound: true,
        dashArray: [4, 4],
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AspectRatio(
        aspectRatio: 2.0,
        child: Padding(
          padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 1,
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const Text('0');
                      if (value == 1) return const Text('1');
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _formatY(value),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: lineBars,
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) =>
                      touchedSpots.map((s) => LineTooltipItem(
                            _formatY(s.y),
                            theme.textTheme.bodySmall ?? const TextStyle(),
                          )).toList(),
                ),
              ),
            ),
            duration: const Duration(milliseconds: 250),
          ),
        ),
      ),
    );
  }

  static double _max(double a, double b, double c) {
    if (a >= b && a >= c) return a;
    if (b >= c) return b;
    return c;
  }

  static String _formatY(double y) {
    if (y >= 1000000) return '${(y / 1e6).toStringAsFixed(1)}M';
    if (y >= 1000) return '${(y / 1000).toStringAsFixed(0)}k';
    return y.toStringAsFixed(0);
  }
}
