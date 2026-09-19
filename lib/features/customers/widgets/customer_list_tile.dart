import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/customer.dart';

class CustomerListTile extends StatelessWidget {
  final Customer customer;

  /// Live-computed total debt for this customer, or null while still
  /// loading — never a value read from the customer row itself.
  final double? totalDebt;
  final VoidCallback onTap;

  const CustomerListTile({
    super.key,
    required this.customer,
    required this.totalDebt,
    required this.onTap,
  });

  String _formatMoney(double value) => formatTsh(value);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasDebt = (totalDebt ?? 0) > 0;

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
            CircleAvatar(
              radius: 21,
              backgroundColor: palette.accent.withValues(alpha: 0.12),
              child: Text(
                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: palette.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer.phone ?? customer.email ?? 'No contact info',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (totalDebt == null)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.8),
              )
            else if (hasDebt)
              StatusBadge(
                label: _formatMoney(totalDebt!),
                tone: BadgeTone.danger,
              )
            else
              StatusBadge(label: 'No debt', tone: BadgeTone.success),
          ],
        ),
      ),
    );
  }
}
