import 'package:flutter/material.dart';

/// نظام الزوايا - من design_plan.md
class AppRadius {
  AppRadius._();

  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 28;
  static const double xxl = 36;
  static const double full = 999;

  static BorderRadius rsm = BorderRadius.circular(sm);
  static BorderRadius rmd = BorderRadius.circular(md);
  static BorderRadius rlg = BorderRadius.circular(lg);
  static BorderRadius rxl = BorderRadius.circular(xl);
  static BorderRadius rxxl = BorderRadius.circular(xxl);
  static BorderRadius rfull = BorderRadius.circular(full);
}
