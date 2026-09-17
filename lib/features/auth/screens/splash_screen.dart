import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    final onboardingDone = await ref.read(onboardingCompleteProvider.future);
    if (!mounted) return;

    if (!onboardingDone) {
      context.go('/onboarding');
      return;
    }

    final hasAdmin = await ref.read(hasAnyUserProvider.future);
    if (!mounted) return;

    if (!hasAdmin) {
      context.go('/auth/setup');
      return;
    }

    final session = await ref.read(sessionProvider.future);
    if (!mounted) return;

    context.go(session != null ? '/home' : '/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.bgPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_rounded, size: 56, color: palette.accent),
            const SizedBox(height: 16),
            Text(
              'Bazaar',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: palette.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
