import 'package:intl/intl.dart';

/// Date helpers for monthly selection and ranges.
/// All month values are 1-based (January = 1).

int daysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

DateTime startOfMonth(int year, int month) {
  return DateTime(year, month, 1);
}

/// Last moment of the given month (23:59:59.999).
DateTime endOfMonthInclusive(int year, int month) {
  return DateTime(year, month, daysInMonth(year, month), 23, 59, 59, 999);
}

/// Previous calendar month as (year, month). January -> (year-1, 12).
(int year, int month) previousMonth(int year, int month) {
  if (month == 1) return (year - 1, 12);
  return (year, month - 1);
}

String formatMonthLabel(int year, int month) {
  final date = DateTime(year, month, 1);
  return DateFormat.yMMMM().format(date);
}

/// Progress through the month: day 1 => 1/days, day N => N/days. Clamped to [0, 1].
double dayIndexToProgress(int dayIndex1based, int daysInMonth) {
  if (daysInMonth <= 0) return 0;
  final day = dayIndex1based.clamp(1, daysInMonth);
  return day / daysInMonth;
}
