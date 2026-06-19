// lib/core/theme/app_text_styles.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // ── Headlines ─────────────────────────────────────────────
  static final headlineLarge = GoogleFonts.cairo(
    fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static final headlineMedium = GoogleFonts.cairo(
    fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static final headlineSmall = GoogleFonts.cairo(
    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );

  // ── Titles ────────────────────────────────────────────────
  static final titleLarge = GoogleFonts.cairo(
    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static final titleMedium = GoogleFonts.cairo(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static final titleSmall = GoogleFonts.cairo(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  // ── Body ──────────────────────────────────────────────────
  static final bodyLarge = GoogleFonts.cairo(
    fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );
  static final bodyMedium = GoogleFonts.cairo(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );
  static final bodySmall = GoogleFonts.cairo(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );

  // ── Label ─────────────────────────────────────────────────
  static final labelLarge = GoogleFonts.cairo(
    fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
  );
  static final labelMedium = GoogleFonts.cairo(
    fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
  );
  static final labelSmall = GoogleFonts.cairo(
    fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.textHint,
  );

  // ── Financial ─────────────────────────────────────────────
  static final amountLarge = GoogleFonts.cairo(
    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static final amountMedium = GoogleFonts.cairo(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
}
