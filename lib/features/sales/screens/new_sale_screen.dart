import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../products/models/product.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_panel.dart';
import '../widgets/negotiate_price_dialog.dart';
import '../widgets/sale_product_card.dart';

final saleCategoriesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final products = await ref.watch(saleProductsProvider.future);
  final categories = products.map((p) => p.category).toSet().toList()..sort();
  return categories;
});

class NewSaleScreen extends ConsumerStatefulWidget {
  const NewSaleScreen({super.key});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onPackageTap(Product product, ProductPackage package) {
    ref.read(cartProvider.notifier).addLine(product, package);
    if (package.pricingType == PricingType.negotiable) {
      final cart = ref.read(cartProvider);
      final line = cart.lines.lastWhere(
        (l) => l.product.id == product.id && l.package.id == package.id,
      );
      showNegotiatePriceDialog(
        context,
        lineId: line.id,
        productName: product.name,
        packageLabel: package.label,
        minPrice: package.minPrice ?? 0,
        maxPrice: package.maxPrice ?? 0,
      );
    }
  }

  Future<void> _checkout() async {
    final result = await ref.read(checkoutControllerProvider.notifier).checkout();
    if (!mounted || result == null) return;
    context.pushReplacement('/home/pos/receipt', extra: result);
  }

  String _friendlyCheckoutError(Object error) {
    final message = error.toString();
    return message.isEmpty ? 'Could not complete sale' : message;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final productsAsync = ref.watch(filteredSaleProductsProvider);
    final filter = ref.watch(saleProductFilterProvider);
    final categoriesAsync = ref.watch(saleCategoriesProvider);
    final checkoutState = ref.watch(checkoutControllerProvider);

    ref.listen(checkoutControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_friendlyCheckoutError(error))),
          );
        },
      );
    });

    final productGrid = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(saleProductFilterProvider.notifier).setSearch('');
                            setState(() {});
                          },
                        ),
                ),
                onChanged: (v) {
                  ref.read(saleProductFilterProvider.notifier).setSearch(v);
                  setState(() {});
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 34,
                child: categoriesAsync.when(
                  data: (categories) => ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CategoryChip(
                        label: 'All',
                        selected: filter.category == null,
                        onTap: () =>
                            ref.read(saleProductFilterProvider.notifier).setCategory(null),
                      ),
                      for (final c in categories) ...[
                        const SizedBox(width: 6),
                        _CategoryChip(
                          label: c,
                          selected: filter.category == c,
                          onTap: () =>
                              ref.read(saleProductFilterProvider.notifier).setCategory(c),
                        ),
                      ],
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return Center(
                  child: Text('No products match', style: TextStyle(color: palette.textSecondary)),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisExtent: 118,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                ),
                itemCount: products.length,
                itemBuilder: (context, i) {
                  final product = products[i];
                  return SaleProductCard(
                    product: product,
                    onPackageTap: (pkg) => _onPackageTap(product, pkg),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Text('Could not load products', style: TextStyle(color: palette.danger)),
            ),
          ),
        ),
      ],
    );

    final cartPanel = CartPanel(onCheckout: _checkout, checkingOut: checkoutState.isLoading);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 760) {
            return Row(
              children: [
                Expanded(flex: 3, child: productGrid),
                SizedBox(width: 360, child: cartPanel),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: productGrid),
              cartPanel,
            ],
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? palette.accent : palette.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? palette.accent : palette.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : palette.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
