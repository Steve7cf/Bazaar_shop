import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_user.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/theme_selector.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign back in with your email and password.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final sessionAsync = ref.watch(sessionProvider);
    final user = sessionAsync.value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: palette.bgSecondary,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: palette.accent.withValues(alpha: 0.14),
                child: Text(
                  (user?.name.isNotEmpty ?? false)
                      ? user!.name.trim()[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? '—',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(color: palette.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: palette.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        user?.role == UserRole.admin ? 'Admin' : 'Cashier',
                        style: TextStyle(
                          color: palette.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const ThemeSelector(),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: palette.bgSecondary,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.lock_outline_rounded, color: palette.textSecondary),
                title: const Text('Change password'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: user == null
                    ? null
                    : () => showChangePasswordDialog(context, user.id),
              ),
              Divider(height: 1, color: palette.border),
              ListTile(
                leading: Icon(Icons.logout_rounded, color: palette.danger),
                title: Text('Log out', style: TextStyle(color: palette.danger)),
                onTap: () => _confirmLogout(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
