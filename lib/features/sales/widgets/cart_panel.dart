import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../customers/providers/customers_provider.dart';
import '../models/cart_line.dart';
import '../models/sale.dart';
import '../providers/cart_provider.dart';

class CartPanel extends ConsumerWidget {
  final VoidCallback onCheckout;
  final bool checkingOut;

  const CartPanel({
    super.key,
    required this.onCheckout,
    required this.checkingOut,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final cart = ref.watch(cartProvider);
    final shortfalls = ref.watch(cartStockShortfallsProvider);

    return Container(
      decoration: BoxDecoration(
        color: palette.bgSecondary,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cart.spansMultipleTills)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 8,
                ),
                color: palette.warning.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 15, color: palette.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'This cart has items from both tills — payment and change will be split automatically',
                        style: TextStyle(fontSize: 11.5, color: palette.warning),
                      ),
                    ),
                  ],
                ),
              ),
            if (shortfalls.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 8,
                ),
                color: palette.danger.withValues(alpha: 0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: shortfalls
                      .map(
                        (s) => Text(
                          s.message,
                          style: TextStyle(fontSize: 11.5, color: palette.danger),
                        ),
                      )
                      .toList(),
                ),
              ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm + 4,
                  AppSpacing.md,
                  4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CustomerPicker(cart: cart),
                    const SizedBox(height: AppSpacing.sm + 4),
                    if (cart.lines.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Cart is empty — tap a product to add it',
                          style: TextStyle(color: palette.textTertiary, fontSize: 13),
                        ),
                      )
                    else
                      ...cart.lines.map((line) => _CartLineRow(line: line)),
                    const Divider(height: AppSpacing.lg),
                    _SummaryRow(label: 'Subtotal', value: formatTsh(cart.subtotal)),
                    const SizedBox(height: 6),
                    _DiscountRow(discount: cart.discount),
                    const SizedBox(height: 6),
                    _SummaryRow(
                      label: 'Total',
                      value: formatTsh(cart.total),
                      emphasize: true,
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    _PaymentMethodRow(method: cart.paymentMethod),
                    const SizedBox(height: AppSpacing.sm),
                    _AmountPaidRow(amountPaid: cart.amountPaid),
                    const SizedBox(height: AppSpacing.sm),
                    if (cart.change > 0)
                      _SummaryRow(
                        label: 'Change',
                        value: formatTsh(cart.change),
                        valueColor: palette.success,
                      )
                    else if (cart.balanceDue > 0)
                      _SummaryRow(
                        label: 'Balance due',
                        value: formatTsh(cart.balanceDue),
                        valueColor: palette.danger,
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                8,
                AppSpacing.md,
                AppSpacing.sm + 4,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (cart.canCheckout && !checkingOut) ? onCheckout : null,
                  child: checkingOut
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Complete Sale'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerPicker extends ConsumerWidget {
  final CartState cart;
  const _CustomerPicker({required this.cart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final customersAsync = ref.watch(customersListProvider);

    return customersAsync.when(
      data: (customers) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String?>(
              initialValue: cart.selectedCustomerId,
              decoration: const InputDecoration(labelText: 'Customer'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Walk-in Customer'),
                ),
                ...customers.map(
                  (c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
                ),
              ],
              onChanged: (id) => ref.read(cartProvider.notifier).selectCustomer(id),
            ),
            if (cart.selectedCustomerId == null) ...[
              const SizedBox(height: 6),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Or type a new customer name (optional)',
                  isDense: true,
                ),
                onChanged: (v) => ref.read(cartProvider.notifier).setTypedCustomerName(v),
              ),
              const SizedBox(height: 4),
              Text(
                'Only needed if this sale results in a balance due',
                style: TextStyle(fontSize: 11, color: palette.textTertiary),
              ),
            ],
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => Text(
        'Could not load customers',
        style: TextStyle(color: palette.danger, fontSize: 12),
      ),
    );
  }
}

class _CartLineRow extends ConsumerWidget {
  final CartLine line;
  const _CartLineRow({required this.line});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                Text(
                  '${line.package.label} · ${formatTsh(line.unitPrice)}'
                  '${line.isNegotiable ? ' (negotiated)' : ''}',
                  style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
                ),
              ],
            ),
          ),
          _QtyStepper(line: line),
          const SizedBox(width: 8),
          SizedBox(
            width: 68,
            child: Text(
              formatTsh(line.lineTotal),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: palette.textTertiary),
            visualDensity: VisualDensity.compact,
            onPressed: () => ref.read(cartProvider.notifier).removeLine(line.id),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends ConsumerWidget {
  final CartLine line;
  const _QtyStepper({required this.line});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final qtyLabel = line.qty == line.qty.roundToDouble()
        ? line.qty.toInt().toString()
        : line.qty.toStringAsFixed(2);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: Icons.remove_rounded,
          onTap: () => ref.read(cartProvider.notifier).updateQty(line.id, line.qty - 1),
        ),
        SizedBox(
          width: 28,
          child: Text(qtyLabel, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
        ),
        _StepperButton(
          icon: Icons.add_rounded,
          onTap: () => ref.read(cartProvider.notifier).updateQty(line.id, line.qty + 1),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.bgTertiary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: palette.textSecondary),
      ),
    );
  }
}

class _DiscountRow extends ConsumerStatefulWidget {
  final double discount;
  const _DiscountRow({required this.discount});

  @override
  ConsumerState<_DiscountRow> createState() => _DiscountRowState();
}

class _DiscountRowState extends ConsumerState<_DiscountRow> {
  late final _controller = TextEditingController(
    text: widget.discount == 0 ? '' : widget.discount.toStringAsFixed(0),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Text('Discount', style: TextStyle(fontSize: 13.5))),
        SizedBox(
          width: 110,
          child: TextField(
            controller: _controller,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(isDense: true, hintText: '0'),
            onChanged: (v) => ref
                .read(cartProvider.notifier)
                .setDiscount(double.tryParse(v.trim()) ?? 0),
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodRow extends ConsumerWidget {
  final SalePaymentMethod method;
  const _PaymentMethodRow({required this.method});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButtonFormField<SalePaymentMethod>(
      initialValue: method,
      decoration: const InputDecoration(labelText: 'Payment method', isDense: true),
      items: SalePaymentMethod.values
          .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
          .toList(),
      onChanged: (m) {
        if (m != null) ref.read(cartProvider.notifier).setPaymentMethod(m);
      },
    );
  }
}

class _AmountPaidRow extends ConsumerStatefulWidget {
  final double amountPaid;
  const _AmountPaidRow({required this.amountPaid});

  @override
  ConsumerState<_AmountPaidRow> createState() => _AmountPaidRowState();
}

class _AmountPaidRowState extends ConsumerState<_AmountPaidRow> {
  late final _controller = TextEditingController(
    text: widget.amountPaid == 0 ? '' : widget.amountPaid.toStringAsFixed(0),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(labelText: 'Amount paid (Tsh)', isDense: true),
      onChanged: (v) => ref
          .read(cartProvider.notifier)
          .setAmountPaid(double.tryParse(v.trim()) ?? 0),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: emphasize ? 15 : 13.5,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            color: emphasize ? palette.textPrimary : palette.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 16 : 13.5,
            fontWeight: FontWeight.w700,
            color: valueColor ?? (emphasize ? palette.textPrimary : palette.textSecondary),
          ),
        ),
      ],
    );
  }
}
