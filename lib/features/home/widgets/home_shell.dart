import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/nav_item.dart';
import 'app_drawer.dart';

class HomeShell extends ConsumerWidget {
  final Widget child;
  final String currentRoute;
  final String title;
  final List<Widget>? actions;

  const HomeShell({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider);
    final role = sessionAsync.value?.role ?? UserRole.admin;
    final userName = sessionAsync.value?.name ?? '';

    final bottomItems = allNavItems
        .where(
          (i) => bottomNavRoutes.contains(i.route) && i.visibleTo.contains(role),
        )
        .toList();

    final selectedIndex = bottomItems.indexWhere(
      (i) => i.route == currentRoute,
    );

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: AppDrawer(
        currentRoute: currentRoute,
        role: role,
        userName: userName,
      ),
      body: SafeArea(top: false, child: child),
      bottomNavigationBar: bottomItems.isEmpty
          ? null
          : BottomNavigationBar(
              currentIndex: selectedIndex < 0 ? 0 : selectedIndex,
              onTap: (i) => context.go(bottomItems[i].route),
              items: bottomItems
                  .map(
                    (i) => BottomNavigationBarItem(
                      icon: Icon(i.icon),
                      activeIcon: Icon(i.activeIcon),
                      label: i.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
