// lib/core/theme/app_text_styles.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const _fontFamily = 'Cairo';

  // ── Headlines ─────────────────────────────────────────────
  static const headlineLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 32,
    fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const headlineMedium = TextStyle(
    fontFamily: _fontFamily, fontSize: 28,
    fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const headlineSmall = TextStyle(
    fontFamily: _fontFamily, fontSize: 24,
    fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );

  // ── Titles ────────────────────────────────────────────────
  static const titleLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 20,
    fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const titleMedium = TextStyle(
    fontFamily: _fontFamily, fontSize: 16,
    fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const titleSmall = TextStyle(
    fontFamily: _fontFamily, fontSize: 14,
    fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  // ── Body ──────────────────────────────────────────────────
  static const bodyLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 16,
    fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );
  static const bodyMedium = TextStyle(
    fontFamily: _fontFamily, fontSize: 14,
    fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );
  static const bodySmall = TextStyle(
    fontFamily: _fontFamily, fontSize: 12,
    fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );

  // ── Label ─────────────────────────────────────────────────
  static const labelLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 14,
    fontWeight: FontWeight.w500, color: AppColors.textSecondary,
  );
  static const labelMedium = TextStyle(
    fontFamily: _fontFamily, fontSize: 12,
    fontWeight: FontWeight.w500, color: AppColors.textSecondary,
  );
  static const labelSmall = TextStyle(
    fontFamily: _fontFamily, fontSize: 10,
    fontWeight: FontWeight.w400, color: AppColors.textHint,
  );

  // ── Financial ─────────────────────────────────────────────
  static const amountLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 24,
    fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const amountMedium = TextStyle(
    fontFamily: _fontFamily, fontSize: 18,
    fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
}
