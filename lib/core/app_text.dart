import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppText {
  AppText._();

  static const display = TextStyle(
    color: AppColors.text,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
    height: 1.1,
  );

  static const title = TextStyle(
    color: AppColors.text,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.7,
  );

  static const section = TextStyle(
    color: AppColors.text,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  static const itemTitle = TextStyle(
    color: AppColors.text,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  static const itemSubtitle = TextStyle(
    color: AppColors.textDim,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const body = TextStyle(
    color: AppColors.textDim,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static const caption = TextStyle(
    color: AppColors.textFaint,
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const overline = TextStyle(
    color: AppColors.textFaint,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  );

  static const button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
}
