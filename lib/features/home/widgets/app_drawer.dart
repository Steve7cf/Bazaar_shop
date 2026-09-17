import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/nav_item.dart';

class AppDrawer extends ConsumerWidget {
  final String currentRoute;
  final UserRole role;
  final String userName;

  const AppDrawer({
    super.key,
    required this.currentRoute,
    required this.role,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = allNavItems.where((i) => i.visibleTo.contains(role));
    const sidebarColor = AppColors.lightSidebar; // stays dark in both themes

    return Drawer(
      backgroundColor: sidebarColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.darkAccent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.darkAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bazaar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          userName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: items.map((item) {
                  final active = currentRoute == item.route;
                  return ListTile(
                    leading: Icon(
                      active ? item.activeIcon : item.icon,
                      color: active
                          ? AppColors.darkAccent
                          : Colors.white.withValues(alpha: 0.65),
                      size: 21,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.75),
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 14.5,
                      ),
                    ),
                    selected: active,
                    selectedTileColor: AppColors.darkAccent.withValues(
                      alpha: 0.12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(item.route);
                    },
                  );
                }).toList(),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: AppColors.darkDanger,
                size: 21,
              ),
              title: Text(
                'Log out',
                style: TextStyle(
                  color: AppColors.darkDanger,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
              onTap: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/auth/login');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
