import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/product_repository.dart';
import '../models/product.dart';
import '../providers/products_provider.dart';
import '../widgets/package_editor_card.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  /// Null when creating a new product.
  final String? productId;

  const ProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameSwController = TextEditingController();
  final _categoryController = TextEditingController(text: 'General');
  final _skuController = TextEditingController();
  final _baseUnitController = TextEditingController(text: 'kg');
  final _notesController = TextEditingController();
  final _stockQtyController = TextEditingController(text: '0');
  final _lowStockController = TextEditingController(text: '5');

  bool _trackStock = true;
  bool _submitting = false;
  bool _loading = false;
  bool _loadFailed = false;
  String? _error;
  final List<PackageDraft> _packages = [PackageDraft.blank()];

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final product = await ref.read(
        productByIdProvider(widget.productId!).future,
      );
      if (!mounted) return;
      if (product == null) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
        return;
      }
      setState(() {
        _loadFrom(product);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameSwController.dispose();
    _categoryController.dispose();
    _skuController.dispose();
    _baseUnitController.dispose();
    _notesController.dispose();
    _stockQtyController.dispose();
    _lowStockController.dispose();
    for (final p in _packages) {
      p.dispose();
    }
    super.dispose();
  }

  void _loadFrom(Product product) {
    _nameController.text = product.name;
    _nameSwController.text = product.nameSw ?? '';
    _categoryController.text = product.category;
    _skuController.text = product.sku ?? '';
    _baseUnitController.text = product.baseUnit;
    _notesController.text = product.notes ?? '';
    _stockQtyController.text = _trimZero(product.stockQty);
    _lowStockController.text = _trimZero(product.lowStockThreshold);
    _trackStock = product.trackStock;

    for (final p in _packages) {
      p.dispose();
    }
    _packages
      ..clear()
      ..addAll(
        product.packages.isEmpty
            ? [PackageDraft.blank()]
            : product.packages.map(PackageDraft.fromPackage),
      );
  }

  String _trimZero(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  void _addPackage() {
    setState(() => _packages.add(PackageDraft.blank()));
  }

  void _removePackage(PackageDraft draft) {
    setState(() {
      _packages.remove(draft);
      draft.dispose();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_packages.isEmpty) {
      setState(() => _error = 'Add at least one package/pricing option');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    // productId used inside toPackage() is only needed for existing rows;
    // for new products the repository assigns the real product id, so any
    // placeholder here is fine — the repository ignores it on insert.
    final packages = _packages
        .map((d) => d.toPackage(widget.productId ?? ''))
        .toList();

    for (final pkg in packages) {
      final validationError = pkg.validate();
      if (validationError != null) {
        setState(() {
          _submitting = false;
          _error = validationError;
        });
        return;
      }
    }

    final controller = ref.read(productsControllerProvider.notifier);
    bool ok;
    if (_isEditing) {
      ok = await controller.updateProduct(
        id: widget.productId!,
        name: _nameController.text,
        nameSw: _nameSwController.text,
        category: _categoryController.text,
        sku: _skuController.text,
        baseUnit: _baseUnitController.text,
        notes: _notesController.text,
        trackStock: _trackStock,
        lowStockThreshold:
            double.tryParse(_lowStockController.text.trim()) ?? 5,
        packages: packages,
      );
    } else {
      ok = await controller.createProduct(
        name: _nameController.text,
        nameSw: _nameSwController.text,
        category: _categoryController.text,
        sku: _skuController.text,
        baseUnit: _baseUnitController.text,
        notes: _notesController.text,
        trackStock: _trackStock,
        stockQty: double.tryParse(_stockQtyController.text.trim()) ?? 0,
        lowStockThreshold:
            double.tryParse(_lowStockController.text.trim()) ?? 5,
        packages: packages,
      );
    }

    if (!mounted) return;

    if (ok) {
      context.pop();
    } else {
      final err = ref.read(productsControllerProvider);
      setState(() {
        _submitting = false;
        _error = err is AsyncError
            ? _friendlyError(err.error)
            : 'Could not save product';
      });
    }
  }

  String _friendlyError(Object error) {
    if (error is ProductValidationException) return error.message;
    return 'Could not save product';
  }

  Future<void> _confirmDeactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate product?'),
        content: const Text(
          'This hides it from Products and New Sale, but keeps its sales '
          'history intact. You can reactivate it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await ref
        .read(productsControllerProvider.notifier)
        .setActive(widget.productId!, false);
    if (!mounted) return;
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (_isEditing && _loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit product')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isEditing && _loadFailed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product')),
        body: const Center(child: Text('Could not load product')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit product' : 'New product'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _submitting ? null : _confirmDeactivate,
              icon: Icon(Icons.visibility_off_outlined, color: palette.danger),
              tooltip: 'Deactivate',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            _SectionLabel('Basics'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _nameSwController,
              decoration: const InputDecoration(
                labelText: 'Swahili name (optional)',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: _skuController,
                    decoration: const InputDecoration(
                      labelText: 'SKU (optional)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _baseUnitController,
              decoration: const InputDecoration(
                labelText: 'Base unit',
                hintText: 'e.g. kg, litre, piece',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.lg),

            _SectionLabel('Stock'),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Track stock'),
              subtitle: const Text(
                'Off = never blocks a sale, never appears in stock reports',
              ),
              value: _trackStock,
              onChanged: (v) => setState(() => _trackStock = v),
            ),
            if (_trackStock) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  if (!_isEditing)
                    Expanded(
                      child: TextFormField(
                        controller: _stockQtyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Starting stock',
                        ),
                      ),
                    ),
                  if (!_isEditing) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _lowStockController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Low-stock threshold',
                      ),
                    ),
                  ),
                ],
              ),
              if (_isEditing) ...[
                const SizedBox(height: 4),
                Text(
                  'Use Restock from the product list to add stock.',
                  style: TextStyle(color: palette.textTertiary, fontSize: 12),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.lg),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel('Packages & pricing'),
                TextButton.icon(
                  onPressed: _addPackage,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add package'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final draft in List.of(_packages))
              PackageEditorCard(
                key: ValueKey(draft.id),
                draft: draft,
                onRemove: () => _removePackage(draft),
                onChanged: () {},
              ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                alignLabelWithHint: true,
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: TextStyle(color: palette.danger, fontSize: 13)),
            ],

            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Add product'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: palette.textTertiary,
      ),
    );
  }
}
