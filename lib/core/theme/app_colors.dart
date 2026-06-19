// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // ── Primary ───────────────────────────────────────────────
  static const primary      = Color(0xFF0F172A); // Deep Navy
  static const primaryDark  = Color(0xFF0B1120); 
  static const primaryLight = Color(0xFF1E293B); 
  static const secondary    = Color(0xFF2563EB); // Travel Blue

  // ── Status ────────────────────────────────────────────────
  static const success      = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const error        = Color(0xFFEF4444); // Danger
  static const errorLight   = Color(0xFFFEE2E2);
  static const warning      = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const info         = Color(0xFF3B82F6);
  static const infoLight    = Color(0xFFDBEAFE);

  // ── Booking Status Colors ─────────────────────────────────
  static const pending    = Color(0xFFF59E0B);
  static const confirmed  = Color(0xFF2563EB);
  static const completed  = Color(0xFF10B981);
  static const cancelled  = Color(0xFFEF4444);
  static const refunded   = Color(0xFF8B5CF6);

  // ── Financial ─────────────────────────────────────────────
  static const debit      = Color(0xFFEF4444);
  static const credit     = Color(0xFF10B981);

  // ── Neutral ───────────────────────────────────────────────
  static const surface      = Color(0xFFFFFFFF);
  static const background   = Color(0xFFF8FAFC);
  static const neutralLight = Color(0xFFF1F5F9);
  static const border       = Color(0xFFE2E8F0);

  // ── Text ──────────────────────────────────────────────────
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textHint      = Color(0xFF94A3B8);

  // ── Aliases ───────────────────────────────────────────────
  static const amountPositive = success;
  static const amountNegative = error;
}
