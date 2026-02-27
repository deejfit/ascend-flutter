import 'package:intl/intl.dart';

const _locale = 'nl_NL';
const _euroSymbol = '€';

/// Format currency for display (default style).
String formatCurrency(num value) {
  return NumberFormat.currency(locale: _locale, symbol: _euroSymbol).format(value);
}

/// Compact currency, no decimals, e.g. "€3.420".
String formatCurrencyCompactNoDecimals(double value) {
  return NumberFormat.currency(
    locale: _locale,
    symbol: _euroSymbol,
    decimalDigits: 0,
  ).format(value);
}

/// Currency with two decimals, e.g. "€1.234,56" (nl_NL) or "€1,234.56" (en_US). We use nl_NL so comma for decimals.
String formatCurrencyTwoDecimals(double value) {
  return NumberFormat.currency(
    locale: _locale,
    symbol: _euroSymbol,
    decimalDigits: 2,
  ).format(value);
}
