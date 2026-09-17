import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../models/onboarding_page_data.dart';

class OnboardingPageView extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingPageView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Center(
              child: Lottie.asset(
                data.lottieAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.storefront_rounded,
                  size: 120,
                  color: palette.accent.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: palette.textSecondary,
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
