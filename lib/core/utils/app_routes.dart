import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/kds/presentation/pages/ched_kds_screen.dart';
import '../../features/main/presentation/pages/bar&resturant/order_history_page.dart';
import '../../features/main/presentation/pages/bar&resturant/report_screen.dart';
import '../../features/main/presentation/pages/bar&resturant/settings_page.dart';
import '../../features/main/presentation/pages/bar&resturant/user_management_page.dart';
import '../../features/waiter/presentation/pages/menu_selection_screen.dart';
import '../../features/waiter/presentation/pages/waiter_dashboard.dart';
import '../../core/utils/routes_name.dart';
import '../../features/main/presentation/pages/bar&resturant/billing_screen.dart';
import '../../features/main/presentation/pages/bar&resturant/dashboard_overview_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/main/presentation/pages/bar&resturant/main_dashboard.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,

    redirect: (context, state) async {
      final storage = GetIt.I<FlutterSecureStorage>();
      final String? token = await storage.read(key: 'access_token');
      final String? role = await storage.read(key: 'user_role');
      final String cleanRole = (role ?? '').toLowerCase().trim();

      final bool isLoggingIn = state.uri.path == AppRoutes.login;
      final bool isOnSplash = state.uri.path == AppRoutes.splash;

      if (token == null || token.isEmpty) {
        if (isLoggingIn || isOnSplash) return null;
        return AppRoutes.login;
      }

      if (isLoggingIn || isOnSplash) {
        if (cleanRole == 'chef' || cleanRole == 'barman') return AppRoutes.chefKds;
        if (cleanRole == 'waiter' || cleanRole == 'staff') return AppRoutes.waiterDashboard;
        return '/dashboard';
      }

      final String currentPath = state.uri.path;

      if (cleanRole == 'chef' || cleanRole == 'barman') {
        if (currentPath.startsWith('/dashboard') ||
            currentPath.startsWith('/reports') ||
            currentPath.startsWith('/billing')) {
          return AppRoutes.chefKds;
        }
      }

      if (cleanRole == 'waiter') {
        if (currentPath.startsWith('/dashboard') ||
            currentPath.startsWith('/reports') ||
            currentPath.startsWith('/manage_user')) {
          return AppRoutes.waiterDashboard;
        }
      }

      return null;
    },

    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),

      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.chefKds,
        builder: (context, state) =>  ChefKDSScreen(),
      ),
      GoRoute(
        path: AppRoutes.waiterDashboard,
        builder: (context, state) =>  WaiterDashboard(),
      ),
    GoRoute(
      path: AppRoutes.menuSelectionScreen,
      builder: (context, state) {
        final data = (state.extra as Map<String, dynamic>?) ?? {};
        return MenuSelectionScreen(data: data);
      },
    ),


      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainDashboard(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardOverviewPage(),
          ),

          GoRoute(
            path: '/billing',
            builder: (context, state) => const BillingPageWrapper(),
          ),

          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/order_history',
            builder: (context, state) => const OrderHistoryScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/manage_user',
            builder: (context, state) => const UserManagementPage(),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text("Page not found: ${state.error}")),
    ),
  );
}