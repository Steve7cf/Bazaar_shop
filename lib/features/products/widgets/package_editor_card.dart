import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../models/product.dart';

/// Editable draft form of a package, tracked separately from ProductPackage
/// so text fields can hold in-progress/invalid text without exceptions.
class PackageDraft {
  String id;
  final TextEditingController labelController;
  final TextEditingController unitTypeController;
  final TextEditingController priceController;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final TextEditingController baseUnitQtyController;
  PricingType pricingType;

  PackageDraft({
    required this.id,
    String label = '',
    String unitType = '',
    PricingType pricingType = PricingType.fixed,
    String price = '',
    String minPrice = '',
    String maxPrice = '',
    String baseUnitQty = '1',
  }) : pricingType = pricingType,
       labelController = TextEditingController(text: label),
       unitTypeController = TextEditingController(text: unitType),
       priceController = TextEditingController(text: price),
       minPriceController = TextEditingController(text: minPrice),
       maxPriceController = TextEditingController(text: maxPrice),
       baseUnitQtyController = TextEditingController(text: baseUnitQty);

  factory PackageDraft.fromPackage(ProductPackage pkg) {
    return PackageDraft(
      id: pkg.id,
      label: pkg.label,
      unitType: pkg.unitType,
      pricingType: pkg.pricingType,
      price: pkg.price?.toString() ?? '',
      minPrice: pkg.minPrice?.toString() ?? '',
      maxPrice: pkg.maxPrice?.toString() ?? '',
      baseUnitQty: pkg.baseUnitQty.toString(),
    );
  }

  factory PackageDraft.blank() => PackageDraft(
    id: 'new_${DateTime.now().microsecondsSinceEpoch}',
  );

  ProductPackage toPackage(String productId) {
    return ProductPackage(
      id: id,
      productId: productId,
      label: labelController.text.trim(),
      unitType: unitTypeController.text.trim(),
      pricingType: pricingType,
      price: pricingType == PricingType.fixed
          ? double.tryParse(priceController.text.trim())
          : double.tryParse(maxPriceController.text.trim()),
      minPrice: pricingType == PricingType.negotiable
          ? double.tryParse(minPriceController.text.trim())
          : null,
      maxPrice: pricingType == PricingType.negotiable
          ? double.tryParse(maxPriceController.text.trim())
          : null,
      baseUnitQty: double.tryParse(baseUnitQtyController.text.trim()) ?? 1,
      active: true,
    );
  }

  void dispose() {
    labelController.dispose();
    unitTypeController.dispose();
    priceController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    baseUnitQtyController.dispose();
  }
}

class PackageEditorCard extends StatefulWidget {
  final PackageDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const PackageEditorCard({
    super.key,
    required this.draft,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<PackageEditorCard> createState() => _PackageEditorCardState();
}

class _PackageEditorCardState extends State<PackageEditorCard> {
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final draft = widget.draft;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: palette.bgTertiary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.labelController,
                  decoration: const InputDecoration(
                    labelText: 'Package label',
                    hintText: 'e.g. 1kg',
                  ),
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: Icon(Icons.close_rounded, color: palette.danger, size: 20),
                tooltip: 'Remove package',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.unitTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Display unit',
                    hintText: 'e.g. kg, tin',
                  ),
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: draft.baseUnitQtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Base unit qty',
                    hintText: 'e.g. 0.5',
                  ),
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<PricingType>(
            segments: const [
              ButtonSegment(value: PricingType.fixed, label: Text('Fixed')),
              ButtonSegment(value: PricingType.negotiable, label: Text('Negotiable')),
            ],
            selected: {draft.pricingType},
            onSelectionChanged: (s) {
              setState(() => draft.pricingType = s.first);
              widget.onChanged();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          if (draft.pricingType == PricingType.fixed)
            TextField(
              controller: draft.priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price (Tsh)',
                hintText: 'e.g. 2500',
              ),
              onChanged: (_) => widget.onChanged(),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: draft.minPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Min price'),
                    onChanged: (_) => widget.onChanged(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: draft.maxPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Max price'),
                    onChanged: (_) => widget.onChanged(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
