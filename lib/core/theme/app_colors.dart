// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // ── Primary ───────────────────────────────────────────────
  static const primary      = Color(0xFF5B5CEB); // Indigo Violet
  static const primaryDark  = Color(0xFF4A4BC4);
  static const primaryLight = Color(0xFFEEEEFD); // soft tint for backgrounds
  static const secondary    = Color(0xFF7B7CF0); // lighter indigo

  // ── Status ────────────────────────────────────────────────
  static const success      = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const error        = Color(0xFFEF4444);
  static const errorLight   = Color(0xFFFEE2E2);
  static const warning      = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const info         = Color(0xFF3B82F6);
  static const infoLight    = Color(0xFFDBEAFE);

  // ── Booking Status Colors ─────────────────────────────────
  static const pending    = Color(0xFFF59E0B);
  static const confirmed  = Color(0xFF5B5CEB);
  static const completed  = Color(0xFF10B981);
  static const cancelled  = Color(0xFFEF4444);
  static const refunded   = Color(0xFF8B5CF6);

  // ── Financial ─────────────────────────────────────────────
  static const debit      = Color(0xFFEF4444);
  static const credit     = Color(0xFF10B981);

  // ── Customer Tags ─────────────────────────────────────────
  static const tagVip       = Color(0xFFD97706);
  static const tagVipLight  = Color(0xFFFEF3C7);
  static const tagFrequent      = Color(0xFF7C3AED);
  static const tagFrequentLight = Color(0xFFEDE9FE);
  static const tagDebtor      = Color(0xFFDC2626);
  static const tagDebtorLight = Color(0xFFFEE2E2);
  static const tagCorporate      = Color(0xFF0284C7);
  static const tagCorporateLight = Color(0xFFE0F2FE);

  // ── Neutral ───────────────────────────────────────────────
  static const surface      = Color(0xFFFFFFFF);
  static const background   = Color(0xFFF8FAFC);
  static const neutralLight = Color(0xFFF1F5F9);
  static const border       = Color(0xFFE5E7EB);

  // ── Text ──────────────────────────────────────────────────
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textHint      = Color(0xFF94A3B8);

  // ── Aliases ───────────────────────────────────────────────
  static const amountPositive = success;
  static const amountNegative = error;
}
