import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/product.dart';

class ProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onRestock;

  const ProductListTile({
    super.key,
    required this.product,
    required this.onTap,
    required this.onRestock,
  });

  String _formatMoney(double value) {
    final rounded = value.round();
    final str = rounded.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final posFromEnd = str.length - i;
      buf.write(str[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write(',');
    }
    return 'Tsh $buf';
  }

  String get _priceLine {
    if (product.packages.isEmpty) return 'No packages';
    final first = product.packages.first;
    final priceStr = first.pricingType == PricingType.negotiable
        ? '${_formatMoney(first.minPrice ?? 0)} – ${_formatMoney(first.maxPrice ?? 0)}'
        : _formatMoney(first.price ?? 0);
    final suffix = product.packages.length > 1
        ? ' +${product.packages.length - 1} more'
        : '';
    return '${first.label} · $priceStr$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color: palette.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                color: palette.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
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
                      if (!product.active)
                        const StatusBadge(label: 'Inactive', tone: BadgeTone.info)
                      else if (product.isOutOfStock)
                        const StatusBadge(label: 'Out of stock', tone: BadgeTone.danger)
                      else if (product.isLowStock)
                        const StatusBadge(label: 'Low stock', tone: BadgeTone.warning),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _priceLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.sell_outlined, size: 12, color: palette.textTertiary),
                      const SizedBox(width: 3),
                      Text(
                        product.category,
                        style: TextStyle(color: palette.textTertiary, fontSize: 12),
                      ),
                      if (product.trackStock) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.inventory_outlined, size: 12, color: palette.textTertiary),
                        const SizedBox(width: 3),
                        Text(
                          '${_trimZero(product.stockQty)} ${product.baseUnit}',
                          style: TextStyle(color: palette.textTertiary, fontSize: 12),
                        ),
                      ] else ...[
                        const SizedBox(width: 10),
                        Text(
                          'Not stock-tracked',
                          style: TextStyle(color: palette.textTertiary, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (product.trackStock)
              IconButton(
                onPressed: onRestock,
                icon: Icon(Icons.add_box_outlined, color: palette.accent),
                tooltip: 'Restock',
              ),
          ],
        ),
      ),
    );
  }

  String _trimZero(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}
