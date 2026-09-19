import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../products/models/product.dart';

class SaleProductCard extends StatelessWidget {
  final Product product;
  final void Function(ProductPackage package) onPackageTap;

  const SaleProductCard({
    super.key,
    required this.product,
    required this.onPackageTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final outOfStock = product.isOutOfStock;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: palette.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (outOfStock)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Out',
                    style: TextStyle(
                      color: palette.danger,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: product.packages.map((pkg) {
              final label = pkg.pricingType == PricingType.negotiable
                  ? '${pkg.label} · negotiable'
                  : '${pkg.label} · ${formatTsh(pkg.price ?? 0)}';
              return InkWell(
                onTap: outOfStock ? null : () => onPackageTap(pkg),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: outOfStock
                        ? palette.bgTertiary
                        : palette.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: outOfStock ? palette.border : palette.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: outOfStock ? palette.textTertiary : palette.accent,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
