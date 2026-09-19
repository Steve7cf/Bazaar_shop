import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/admin_setup_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/customers/screens/customer_detail_screen.dart';
import '../../features/customers/screens/customer_form_screen.dart';
import '../../features/customers/screens/customers_screen.dart';
import '../../features/debts/screens/debts_screen.dart';
import '../../features/home/models/nav_item.dart';
import '../../features/home/screens/dashboard_screen.dart';
import '../../features/home/screens/placeholder_screen.dart';
import '../../features/home/widgets/home_shell.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/products/screens/product_form_screen.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/sales/screens/new_sale_screen.dart';
import '../../features/sales/screens/receipt_screen.dart';
import '../../data/repositories/sale_repository.dart';

final _placeholderRoutes = <String, ({String title, IconData icon})>{
  '/home/sales': (title: 'Sales History', icon: Icons.receipt_long_rounded),
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
        path: '/home/pos',
        builder: (context, state) => const HomeShell(
          currentRoute: '/home/pos',
          title: 'New Sale',
          child: NewSaleScreen(),
        ),
      ),
      GoRoute(
        path: '/home/pos/receipt',
        builder: (context, state) => ReceiptScreen(
          result: state.extra as CompletedSale,
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
        path: '/home/customers',
        builder: (context, state) => const HomeShell(
          currentRoute: '/home/customers',
          title: 'Customers',
          child: CustomersScreen(),
        ),
      ),
      GoRoute(
        path: '/home/customers/new',
        builder: (context, state) => const CustomerFormScreen(),
      ),
      GoRoute(
        path: '/home/customers/:id',
        builder: (context, state) => CustomerDetailScreen(
          customerId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/home/customers/:id/edit',
        builder: (context, state) => CustomerFormScreen(
          customerId: state.pathParameters['id'],
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
      GoRoute(
        path: '/home/debts',
        builder: (context, state) => const HomeShell(
          currentRoute: '/home/debts',
          title: 'Debts',
          child: DebtsScreen(),
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
