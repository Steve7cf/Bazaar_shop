import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum BadgeTone { success, warning, danger, info }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;

  const StatusBadge({super.key, required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = switch (tone) {
      BadgeTone.success => palette.success,
      BadgeTone.warning => palette.warning,
      BadgeTone.danger => palette.danger,
      BadgeTone.info => palette.accent,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
