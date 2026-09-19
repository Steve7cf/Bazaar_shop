import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/status_badge.dart';
import '../../debts/models/debt.dart';
import '../providers/customers_provider.dart';
import '../widgets/record_payment_dialog.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime d) => '${_monthNames[d.month - 1]} ${d.day}, ${d.year}';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  String _formatMoney(double value) => formatTsh(value);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final customerAsync = ref.watch(customerByIdProvider(customerId));
    final totalDebtAsync = ref.watch(customerTotalDebtProvider(customerId));
    final debtsAsync = ref.watch(customerDebtsProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer'),
        actions: [
          customerAsync.maybeWhen(
            data: (c) => c == null
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        context.push('/home/customers/$customerId/edit'),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: customerAsync.when(
        data: (customer) {
          if (customer == null) {
            return const Center(child: Text('Customer not found'));
          }
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: palette.accent.withValues(alpha: 0.12),
                          child: Text(
                            customer.name.isNotEmpty
                                ? customer.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: palette.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
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
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (customer.phone != null)
                                Text(
                                  customer.phone!,
                                  style: TextStyle(color: palette.textSecondary),
                                ),
                              if (customer.email != null)
                                Text(
                                  customer.email!,
                                  style: TextStyle(color: palette.textSecondary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (customer.address != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 15, color: palette.textTertiary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customer.address!,
                              style: TextStyle(color: palette.textSecondary, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (customer.notes != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        customer.notes!,
                        style: TextStyle(color: palette.textTertiary, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.receipt_long_outlined,
                      label: 'Lifetime purchases',
                      value: _formatMoney(customer.totalPurchases),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: totalDebtAsync.when(
                      data: (total) => _StatTile(
                        icon: Icons.request_quote_outlined,
                        label: 'Outstanding debt',
                        value: _formatMoney(total),
                        valueColor: total > 0 ? palette.danger : palette.success,
                      ),
                      loading: () => const _StatTile(
                        icon: Icons.request_quote_outlined,
                        label: 'Outstanding debt',
                        value: '…',
                      ),
                      error: (_, __) => const _StatTile(
                        icon: Icons.request_quote_outlined,
                        label: 'Outstanding debt',
                        value: '—',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              Text('Debt history', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              debtsAsync.when(
                data: (debts) {
                  if (debts.isEmpty) {
                    return const _EmptyHint(
                      icon: Icons.check_circle_outline_rounded,
                      text: 'No debts on record',
                    );
                  }
                  return Column(
                    children: debts
                        .map(
                          (debt) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _DebtTile(
                              debt: debt,
                              customerId: customerId,
                              formatMoney: _formatMoney,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const _EmptyHint(
                  icon: Icons.error_outline_rounded,
                  text: 'Could not load debt history',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text('Purchase history', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              // Sales history isn't built yet — this fills in once the New
              // Sale / Sales History feature lands and can query sales by
              // customer_id.
              const _EmptyHint(
                icon: Icons.history_rounded,
                text: 'Purchase history will appear here once sales are recorded',
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load customer')),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

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
          Icon(icon, size: 18, color: palette.textSecondary),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: valueColor ?? palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: palette.textSecondary)),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.bgTertiary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: palette.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: palette.textTertiary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _DebtTile extends StatelessWidget {
  final Debt debt;
  final String customerId;
  final String Function(double) formatMoney;

  const _DebtTile({
    required this.debt,
    required this.customerId,
    required this.formatMoney,
  });

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
                  formatMoney(debt.originalAmount),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusBadge(label: label, tone: tone),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _formatDate(debt.createdAt),
            style: TextStyle(color: palette.textTertiary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Balance: ${formatMoney(debt.balance)}',
                style: TextStyle(
                  color: debt.balance > 0 ? palette.danger : palette.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (debt.status != DebtStatus.settled)
                TextButton(
                  onPressed: () => showRecordPaymentDialog(
                    context,
                    debt: debt,
                    customerId: customerId,
                  ),
                  child: const Text('Record payment'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
