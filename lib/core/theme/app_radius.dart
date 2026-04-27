import 'package:flutter/material.dart';

/// نظام الزوايا - من design_plan.md
class AppRadius {
  AppRadius._();

  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double full = 12; // Pill shapes are now just rounded rectangles

  static BorderRadius rsm = BorderRadius.circular(sm);
  static BorderRadius rmd = BorderRadius.circular(md);
  static BorderRadius rlg = BorderRadius.circular(lg);
  static BorderRadius rxl = BorderRadius.circular(xl);
  static BorderRadius rxxl = BorderRadius.circular(xxl);
  static BorderRadius rfull = BorderRadius.circular(full);
}
