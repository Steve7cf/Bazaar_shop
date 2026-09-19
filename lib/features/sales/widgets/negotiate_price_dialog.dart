import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../providers/cart_provider.dart';

/// Shown right after a negotiable package is added to the cart — the line
/// exists but can't be checked out until a price is confirmed here.
Future<void> showNegotiatePriceDialog(
  BuildContext context, {
  required String lineId,
  required String productName,
  required String packageLabel,
  required double minPrice,
  required double maxPrice,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => NegotiatePriceDialog(
      lineId: lineId,
      productName: productName,
      packageLabel: packageLabel,
      minPrice: minPrice,
      maxPrice: maxPrice,
    ),
  );
}

class NegotiatePriceDialog extends ConsumerStatefulWidget {
  final String lineId;
  final String productName;
  final String packageLabel;
  final double minPrice;
  final double maxPrice;

  const NegotiatePriceDialog({
    super.key,
    required this.lineId,
    required this.productName,
    required this.packageLabel,
    required this.minPrice,
    required this.maxPrice,
  });

  @override
  ConsumerState<NegotiatePriceDialog> createState() => _NegotiatePriceDialogState();
}

class _NegotiatePriceDialogState extends ConsumerState<NegotiatePriceDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final price = double.tryParse(_controller.text.trim());
    if (price == null) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    final error = ref
        .read(cartProvider.notifier)
        .setNegotiatedPrice(widget.lineId, price);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop();
  }

  void _cancel() {
    ref.read(cartProvider.notifier).removeLine(widget.lineId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AlertDialog(
      title: const Text('Negotiate price'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.productName} · ${widget.packageLabel}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Allowed range: ${formatTsh(widget.minPrice)} – ${formatTsh(widget.maxPrice)}',
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Agreed price (Tsh)'),
            onSubmitted: (_) => _confirm(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: palette.danger, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: _cancel, child: const Text('Cancel')),
        ElevatedButton(onPressed: _confirm, child: const Text('Confirm')),
      ],
    );
  }
}
