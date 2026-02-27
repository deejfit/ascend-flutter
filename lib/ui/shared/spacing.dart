import 'package:flutter/material.dart';

/// Shared spacing: const SizedBox gaps for calm, spacious layout.
class Spacing {
  Spacing._();

  // Vertical gaps (for stacking content)
  static const SizedBox gap8 = SizedBox(height: 8);
  static const SizedBox gap12 = SizedBox(height: 12);
  static const SizedBox gap16 = SizedBox(height: 16);
  static const SizedBox gap24 = SizedBox(height: 24);
  static const SizedBox gap32 = SizedBox(height: 32);

  // Numeric values when a double is needed (e.g. padding)
  static const double xs = 8;
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 48;
  static const double xxl = 64;
}
