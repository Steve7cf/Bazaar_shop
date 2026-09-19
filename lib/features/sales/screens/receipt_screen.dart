import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../data/repositories/sale_repository.dart';
import '../models/sale.dart';

class ReceiptScreen extends StatelessWidget {
  final CompletedSale result;
  const ReceiptScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final sales = result.all;
    final combinedTotal = sales.fold<double>(0, (s, sale) => s + sale.total);
    final combinedPaid = sales.fold<double>(0, (s, sale) => s + sale.amountPaid);
    final combinedChange = sales.fold<double>(0, (s, sale) => s + sale.change);
    final combinedBalance = sales.fold<double>(0, (s, sale) => s + sale.balanceDue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale complete'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: palette.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: palette.success, size: 32),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sales.length > 1 ? 'Both sales recorded' : 'Sale recorded',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        sales.map((s) => s.invoiceNo).join(' · '),
                        style: TextStyle(color: palette.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          for (final sale in sales) ...[
            _SaleCard(sale: sale),
            const SizedBox(height: AppSpacing.sm),
          ],

          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 4),
            decoration: BoxDecoration(
              color: palette.bgSecondary,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              children: [
                _row(context, 'Total', formatTsh(combinedTotal), emphasize: true),
                const SizedBox(height: 6),
                _row(context, 'Amount paid', formatTsh(combinedPaid)),
                if (combinedChange > 0) ...[
                  const SizedBox(height: 6),
                  _row(context, 'Change', formatTsh(combinedChange), color: palette.success),
                ],
                if (combinedBalance > 0) ...[
                  const SizedBox(height: 6),
                  _row(context, 'Balance due', formatTsh(combinedBalance), color: palette.danger),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.go('/home/pos'),
              child: const Text('New sale'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => context.go('/home/dashboard'),
              child: const Text('Back to dashboard'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool emphasize = false, Color? color}) {
    final palette = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: emphasize ? 15 : 13.5,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            color: palette.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 16 : 13.5,
            fontWeight: FontWeight.w700,
            color: color ?? palette.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SaleCard extends StatelessWidget {
  final Sale sale;
  const _SaleCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  sale.till.label,
                  style: TextStyle(color: palette.accent, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(sale.invoiceNo, style: TextStyle(color: palette.textTertiary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in sale.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.productName} · ${item.packageLabel} × ${_trimZero(item.qty)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(formatTsh(item.lineTotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const Divider(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Till total', style: TextStyle(fontSize: 13, color: palette.textSecondary)),
              Text(formatTsh(sale.total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  String _trimZero(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}
