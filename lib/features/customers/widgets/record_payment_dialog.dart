import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../debts/models/debt.dart';
import '../providers/customers_provider.dart';

Future<void> showRecordPaymentDialog(
  BuildContext context, {
  required Debt debt,
  required String customerId,
}) {
  return showDialog(
    context: context,
    builder: (_) => RecordPaymentDialog(debt: debt, customerId: customerId),
  );
}

class RecordPaymentDialog extends ConsumerStatefulWidget {
  final Debt debt;
  final String customerId;

  const RecordPaymentDialog({
    super.key,
    required this.debt,
    required this.customerId,
  });

  @override
  ConsumerState<RecordPaymentDialog> createState() =>
      _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<RecordPaymentDialog> {
  final _amountController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter an amount greater than zero');
      return;
    }
    if (amount > widget.debt.balance) {
      setState(() => _error = 'Amount cannot exceed the outstanding balance');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final ok = await ref
        .read(customersControllerProvider.notifier)
        .recordDebtPayment(
          debtId: widget.debt.id,
          customerId: widget.customerId,
          amount: amount,
          method: _method,
        );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _submitting = false;
        _error = 'Could not record payment — try again';
      });
    }
  }

  String _formatMoney(double value) => formatTsh(value);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AlertDialog(
      title: const Text('Record payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Outstanding balance: ${_formatMoney(widget.debt.balance)}',
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount paid (Tsh)'),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<PaymentMethod>(
            initialValue: _method,
            decoration: const InputDecoration(labelText: 'Payment method'),
            items: const [
              DropdownMenuItem(value: PaymentMethod.cash, child: Text('Cash')),
              DropdownMenuItem(
                value: PaymentMethod.mobile,
                child: Text('Mobile Money'),
              ),
              DropdownMenuItem(
                value: PaymentMethod.bank,
                child: Text('Bank Transfer'),
              ),
              DropdownMenuItem(value: PaymentMethod.other, child: Text('Other')),
            ],
            onChanged: (v) => setState(() => _method = v ?? PaymentMethod.cash),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: palette.danger, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Record payment'),
        ),
      ],
    );
  }
}
