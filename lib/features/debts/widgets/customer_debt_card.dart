import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/status_badge.dart';
import '../../customers/widgets/record_payment_dialog.dart';
import '../models/debt.dart';
import '../providers/debts_provider.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime d) =>
    '${_monthNames[d.month - 1]} ${d.day}, ${d.year}';

class CustomerDebtCard extends StatefulWidget {
  final CustomerDebtGroup group;
  final VoidCallback onTap;

  const CustomerDebtCard({super.key, required this.group, required this.onTap});

  @override
  State<CustomerDebtCard> createState() => _CustomerDebtCardState();
}

class _CustomerDebtCardState extends State<CustomerDebtCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final group = widget.group;
    final customer = group.customer;

    return Container(
      decoration: BoxDecoration(
        color: palette.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.border),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: palette.accent.withValues(alpha: 0.12),
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?',
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
                          '${group.debts.length} ${group.debts.length == 1 ? 'debt' : 'debts'}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatTsh(group.totalBalance),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: palette.danger,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: palette.textTertiary,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: palette.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm + 2,
                AppSpacing.md,
                AppSpacing.sm + 2,
              ),
              child: Column(
                children: [
                  for (final debt in group.debts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _DebtRow(debt: debt, customerId: customer.id),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: widget.onTap,
                      icon: const Icon(Icons.person_outline_rounded, size: 16),
                      label: const Text('View customer'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DebtRow extends StatelessWidget {
  final Debt debt;
  final String customerId;

  const _DebtRow({required this.debt, required this.customerId});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tone = switch (debt.status) {
      DebtStatus.settled => BadgeTone.success,
      DebtStatus.partial => BadgeTone.warning,
      DebtStatus.open => BadgeTone.danger,
    };
    final label = switch (debt.status) {
      DebtStatus.settled => 'Settled',
      DebtStatus.partial => 'Partial',
      DebtStatus.open => 'Open',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: palette.bgTertiary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                formatTsh(debt.originalAmount),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(label: label, tone: tone),
              const Spacer(),
              Text(
                _formatDate(debt.createdAt),
                style: TextStyle(fontSize: 11.5, color: palette.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Balance: ${formatTsh(debt.balance)}',
                style: TextStyle(
                  color: debt.balance > 0 ? palette.danger : palette.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 30),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => showRecordPaymentDialog(
                  context,
                  debt: debt,
                  customerId: customerId,
                ),
                child: const Text('Record payment', style: TextStyle(fontSize: 12.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
