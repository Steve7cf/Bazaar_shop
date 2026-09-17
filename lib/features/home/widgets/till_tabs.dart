import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

enum TillFilter { all, general, drinks }

extension TillFilterLabel on TillFilter {
  String get label => switch (this) {
    TillFilter.all => 'Whole Shop',
    TillFilter.general => 'General',
    TillFilter.drinks => 'Drinks',
  };
}

class TillTabs extends StatelessWidget {
  final TillFilter value;
  final ValueChanged<TillFilter> onChanged;

  const TillTabs({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.bgTertiary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: TillFilter.values.map((f) {
          final active = f == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? palette.bgSecondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  f.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active ? palette.accent : palette.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
