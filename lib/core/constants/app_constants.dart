// lib/core/constants/app_constants.dart

class AppConstants {
  // ── Supabase ──────────────────────────────────────────────
  // TODO: Replace with your actual Supabase credentials
  static const supabaseUrl     = 'https://YOUR_PROJECT.supabase.co';
  static const supabaseAnonKey = 'YOUR_ANON_KEY';

  // ── Booking Number Prefixes ───────────────────────────────
  static const prefixBooking = 'BK';
  static const prefixPayment = 'PAY';
  static const prefixExpense = 'EXP';
  static const prefixCustomer = 'CUS';

  // ── Currencies ────────────────────────────────────────────
  static const defaultCurrency = 'EGP';
  static const currencies = ['EGP', 'USD', 'EUR'];

  // ── Sync ──────────────────────────────────────────────────
  static const syncIntervalMinutes = 5;
  static const syncBatchSize       = 50;
  static const syncMaxRetries      = 3;

  // ── Backup ────────────────────────────────────────────────
  static const maxBackups = 7;

  // ── Booking Types ─────────────────────────────────────────
  static const bookingTypes = ['flight', 'hotel', 'tour', 'visa', 'other'];

  // ── Payment Methods ───────────────────────────────────────
  static const paymentMethods = [
    'cash', 'bank_transfer', 'credit_card',
    'instapay', 'vodafone_cash', 'other',
  ];
}
