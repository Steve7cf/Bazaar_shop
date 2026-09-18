import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/admin_setup_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/home/models/nav_item.dart';
import '../../features/home/screens/dashboard_screen.dart';
import '../../features/home/screens/placeholder_screen.dart';
import '../../features/home/widgets/home_shell.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/products/screens/product_form_screen.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

final _placeholderRoutes = <String, ({String title, IconData icon})>{
  '/home/pos': (title: 'New Sale', icon: Icons.point_of_sale_rounded),
  '/home/sales': (title: 'Sales History', icon: Icons.receipt_long_rounded),
  '/home/customers': (title: 'Customers', icon: Icons.people_rounded),
  '/home/debts': (title: 'Debts', icon: Icons.request_quote_rounded),
  '/home/loans': (title: 'Personal Loans', icon: Icons.handshake_rounded),
  '/home/expenses': (title: 'Matumizi', icon: Icons.payments_rounded),
  '/home/reports': (title: 'Reports', icon: Icons.bar_chart_rounded),
  '/home/insights': (title: 'Business Insights', icon: Icons.insights_rounded),
  '/home/staff': (title: 'Staff', icon: Icons.badge_rounded),
  '/home/audit-log': (title: 'Audit Log', icon: Icons.fact_check_rounded),
};

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/setup',
        builder: (context, state) => const AdminSetupScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        redirect: (context, state) => '/home/dashboard',
      ),
      GoRoute(
        path: '/home/dashboard',
        builder: (context, state) => const HomeShell(
          currentRoute: '/home/dashboard',
          title: 'Dashboard',
          child: DashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/home/products',
        builder: (context, state) => const HomeShell(
          currentRoute: '/home/products',
          title: 'Products',
          child: ProductsScreen(),
        ),
      ),
      GoRoute(
        path: '/home/products/new',
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/home/products/:id',
        builder: (context, state) => ProductFormScreen(
          productId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/home/profile',
        builder: (context, state) => const HomeShell(
          currentRoute: '/home/profile',
          title: 'Profile',
          child: ProfileScreen(),
        ),
      ),
      ..._placeholderRoutes.entries.map(
        (e) => GoRoute(
          path: e.key,
          builder: (context, state) => HomeShell(
            currentRoute: e.key,
            title: e.value.title,
            child: PlaceholderScreen(title: e.value.title, icon: e.value.icon),
          ),
        ),
      ),
    ],
  );
});
