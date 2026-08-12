import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/common/widgets/app_scaffold.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/billing/presentation/billing_screen.dart';
import '../features/stock/presentation/stock_screen.dart';
import '../features/purchase/presentation/purchase_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppScaffold(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/billing',
          builder: (context, state) => const BillingScreen(),
        ),
        GoRoute(
          path: '/stock',
          builder: (context, state) {
            final filter = state.uri.queryParameters['filter'];
            final action = state.uri.queryParameters['action'];
            return StockScreen(
              initialFilter: filter,
              initialOpenAdd: action == 'add',
            );
          },
        ),
        GoRoute(
          path: '/purchase',
          builder: (context, state) {
            final medId = state.uri.queryParameters['medId'];
            return PurchaseScreen(initialMedicineId: medId);
          },
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
