// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/dashboard/screens/finance_dashboard_screen.dart';
import '../../features/customers/screens/customers_list_screen.dart';
import '../../features/customers/screens/customer_detail_screen.dart';
import '../../features/customers/screens/customer_form_screen.dart';
import '../../features/bookings/screens/bookings_list_screen.dart';
import '../../features/bookings/screens/booking_detail_screen.dart';
import '../../features/bookings/screens/booking_form_screen.dart';
import '../../features/payments/screens/payments_list_screen.dart';
import '../../features/payments/screens/payment_form_screen.dart';
import '../../features/payments/screens/payment_detail_screen.dart';
import '../../features/reports/screens/reports_menu_screen.dart';
import '../../features/reports/screens/sales_report_screen.dart';
import '../../features/reports/screens/debtors_report_screen.dart';
import '../../features/ledger/screens/ledger_screen.dart';
import '../../features/expenses/screens/expenses_list_screen.dart';
import '../../features/settings/screens/login_screen.dart';
import '../../features/settings/screens/initial_pull_screen.dart';
import '../../features/settings/screens/sync_settings_screen.dart';
import '../../features/settings/screens/backup_screen.dart';
import '../../features/settings/screens/more_menu_screen.dart';
import '../../features/ai/screens/ai_assistant_screen.dart';
import '../../features/reports/screens/airline_performance_screen.dart';
import '../../features/reports/screens/top_customers_report_screen.dart';
import '../../shared/screens/shell_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // ── Shell (Bottom Nav) ─────────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            builder: (c, s) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/bookings',
            name: 'bookings',
            builder: (c, s) => const BookingsListScreen(),
          ),
          GoRoute(
            path: '/finance',
            name: 'finance',
            builder: (c, s) => const FinanceDashboardScreen(),
          ),
          GoRoute(
            path: '/more',
            name: 'more',
            builder: (c, s) => const MoreMenuScreen(),
          ),
        ],
      ),

      // ── Additional Main Routes (Out of Bottom Nav) ────────
      GoRoute(
        path: '/customers',
        name: 'customers',
        builder: (c, s) => const CustomersListScreen(),
      ),
      GoRoute(
        path: '/payments',
        name: 'payments',
        builder: (c, s) => const PaymentsListScreen(),
      ),
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (c, s) => const ReportsMenuScreen(),
      ),

      // ── Customer Routes ───────────────────────────────────
      GoRoute(
        path: '/customers/new',
        builder: (c, s) => const CustomerFormScreen(),
      ),
      GoRoute(
        path: '/customers/:id',
        builder: (c, s) => CustomerDetailScreen(
          customerId: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/customers/:id/edit',
        builder: (c, s) => CustomerFormScreen(
          customerId: s.pathParameters['id'],
        ),
      ),

      // ── Booking Routes ────────────────────────────────────
      GoRoute(
        path: '/bookings/new',
        builder: (c, s) => const BookingFormScreen(),
      ),
      GoRoute(
        path: '/bookings/:id',
        builder: (c, s) => BookingDetailScreen(
          bookingId: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/bookings/:id/edit',
        builder: (c, s) => BookingFormScreen(
          bookingId: s.pathParameters['id'],
        ),
      ),

      // ── Payment Routes ────────────────────────────────────
      GoRoute(
        path: '/payments/new',
        builder: (c, s) => const PaymentFormScreen(),
      ),
      GoRoute(
        path: '/payments/:id',
        builder: (c, s) => PaymentDetailScreen(
          paymentId: s.pathParameters['id']!,
        ),
      ),

      // ── Report Routes ─────────────────────────────────────
      GoRoute(
        path: '/reports/sales',
        builder: (c, s) => const SalesReportScreen(),
      ),
      GoRoute(
        path: '/reports/debtors',
        builder: (c, s) => const DebtorsReportScreen(),
      ),
      GoRoute(
        path: '/reports/airlines',
        builder: (c, s) => const AirlinePerformanceScreen(),
      ),
      GoRoute(
        path: '/reports/top-customers',
        builder: (c, s) => const TopCustomersReportScreen(),
      ),
      GoRoute(
        path: '/ai',
        builder: (c, s) => const AiAssistantScreen(),
      ),

      // ── Ledger & Expenses ─────────────────────────────────
      GoRoute(
        path: '/ledger',
        builder: (c, s) => const LedgerScreen(),
      ),
      GoRoute(
        path: '/expenses',
        builder: (c, s) => const ExpensesListScreen(),
      ),
      GoRoute(
        path: '/expenses/new',
        builder: (c, s) => const ExpensesListScreen(),
      ),

      // ── Settings ──────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (c, s) => const LoginScreen(),
      ),
      GoRoute(
        path: '/initial-pull',
        builder: (c, s) => const InitialPullScreen(),
      ),
      GoRoute(
        path: '/settings/sync',
        builder: (c, s) => const SyncSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/backup',
        builder: (c, s) => const BackupScreen(),
      ),
    ],
  );
}
