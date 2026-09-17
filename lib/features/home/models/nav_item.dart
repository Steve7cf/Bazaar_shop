import 'package:flutter/material.dart';
import '../../auth/providers/auth_provider.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final List<UserRole> visibleTo;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    required this.visibleTo,
  });
}

const allNavItems = [
  NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    route: '/home/dashboard',
    visibleTo: [UserRole.admin],
  ),
  NavItem(
    label: 'New Sale',
    icon: Icons.point_of_sale_outlined,
    activeIcon: Icons.point_of_sale_rounded,
    route: '/home/pos',
    visibleTo: [UserRole.admin, UserRole.cashier],
  ),
  NavItem(
    label: 'Sales',
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long_rounded,
    route: '/home/sales',
    visibleTo: [UserRole.admin, UserRole.cashier],
  ),
  NavItem(
    label: 'Products',
    icon: Icons.inventory_2_outlined,
    activeIcon: Icons.inventory_2_rounded,
    route: '/home/products',
    visibleTo: [UserRole.admin],
  ),
  NavItem(
    label: 'Customers',
    icon: Icons.people_outline_rounded,
    activeIcon: Icons.people_rounded,
    route: '/home/customers',
    visibleTo: [UserRole.admin, UserRole.cashier],
  ),
  NavItem(
    label: 'Debts',
    icon: Icons.request_quote_outlined,
    activeIcon: Icons.request_quote_rounded,
    route: '/home/debts',
    visibleTo: [UserRole.admin, UserRole.cashier],
  ),
  NavItem(
    label: 'Loans',
    icon: Icons.handshake_outlined,
    activeIcon: Icons.handshake_rounded,
    route: '/home/loans',
    visibleTo: [UserRole.admin],
  ),
  NavItem(
    label: 'Matumizi',
    icon: Icons.payments_outlined,
    activeIcon: Icons.payments_rounded,
    route: '/home/expenses',
    visibleTo: [UserRole.admin],
  ),
  NavItem(
    label: 'Reports',
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart_rounded,
    route: '/home/reports',
    visibleTo: [UserRole.admin],
  ),
  NavItem(
    label: 'Insights',
    icon: Icons.insights_outlined,
    activeIcon: Icons.insights_rounded,
    route: '/home/insights',
    visibleTo: [UserRole.admin],
  ),
  NavItem(
    label: 'Staff',
    icon: Icons.badge_outlined,
    activeIcon: Icons.badge_rounded,
    route: '/home/staff',
    visibleTo: [UserRole.admin],
  ),
  NavItem(
    label: 'Audit Log',
    icon: Icons.fact_check_outlined,
    activeIcon: Icons.fact_check_rounded,
    route: '/home/audit-log',
    visibleTo: [UserRole.admin],
  ),
  NavItem(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    route: '/home/profile',
    visibleTo: [UserRole.admin, UserRole.cashier],
  ),
];

/// Bottom nav shows only the highest-priority items; the rest live in the drawer.
const bottomNavRoutes = [
  '/home/dashboard',
  '/home/pos',
  '/home/sales',
  '/home/debts',
];
