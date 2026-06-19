// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // ── Primary ───────────────────────────────────────────────
  static const primary      = Color(0xFF2E7D32); // Green 800
  static const primaryDark  = Color(0xFF1B5E20); // Green 900
  static const primaryLight = Color(0xFF4CAF50); // Green 500
  static const secondary    = Color(0xFF00695C); // Teal 800

  // ── Status ────────────────────────────────────────────────
  static const success      = Color(0xFF2E7D32);
  static const successLight = Color(0xFFE8F5E9);
  static const error        = Color(0xFFC62828);
  static const errorLight   = Color(0xFFFFEBEE);
  static const warning      = Color(0xFFF57F17);
  static const warningLight = Color(0xFFFFF8E1);
  static const info         = Color(0xFF0277BD);
  static const infoLight    = Color(0xFFE1F5FE);

  // ── Booking Status Colors ─────────────────────────────────
  static const pending    = Color(0xFFF57F17);
  static const confirmed  = Color(0xFF1565C0);
  static const completed  = Color(0xFF2E7D32);
  static const cancelled  = Color(0xFFC62828);
  static const refunded   = Color(0xFF6A1B9A);

  // ── Financial ─────────────────────────────────────────────
  static const debit      = Color(0xFFC62828);
  static const credit     = Color(0xFF2E7D32);

  // ── Neutral ───────────────────────────────────────────────
  static const surface      = Color(0xFFFFFFFF);
  static const background   = Color(0xFFF5F5F5);
  static const neutralLight = Color(0xFFEEEEEE);
  static const border       = Color(0xFFE0E0E0);

  // ── Text ──────────────────────────────────────────────────
  static const textPrimary   = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textHint      = Color(0xFFBDBDBD);

  // ── Aliases ───────────────────────────────────────────────
  static const amountPositive = success;
  static const amountNegative = error;
}
