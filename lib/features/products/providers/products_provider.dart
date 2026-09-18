import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/product_repository.dart';
import '../models/product.dart';

class ProductsFilter {
  final String search;
  final String? category;

  const ProductsFilter({this.search = '', this.category});

  ProductsFilter copyWith({String? search, String? category, bool clearCategory = false}) {
    return ProductsFilter(
      search: search ?? this.search,
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}

class ProductsFilterNotifier extends Notifier<ProductsFilter> {
  @override
  ProductsFilter build() => const ProductsFilter();

  void setSearch(String value) => state = state.copyWith(search: value);

  void setCategory(String? category) {
    state = category == null
        ? state.copyWith(clearCategory: true)
        : state.copyWith(category: category);
  }
}

final productsFilterProvider =
    NotifierProvider<ProductsFilterNotifier, ProductsFilter>(
      ProductsFilterNotifier.new,
    );

final productsListProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) async {
  final filter = ref.watch(productsFilterProvider);
  return ProductRepository.instance.getAll(
    search: filter.search,
    category: filter.category,
  );
});

final productCategoriesProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  // Depend on the list so newly-used categories show up after saves.
  ref.watch(productsListProvider);
  return ProductRepository.instance.getCategories();
});

final productByIdProvider = FutureProvider.autoDispose
    .family<Product?, String>((ref, id) {
      return ProductRepository.instance.getById(id);
    });

class ProductsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> createProduct({
    required String name,
    String? nameSw,
    required String category,
    String? sku,
    required String baseUnit,
    String? notes,
    required bool trackStock,
    required double stockQty,
    required double lowStockThreshold,
    required List<ProductPackage> packages,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ProductRepository.instance.create(
        name: name,
        nameSw: nameSw,
        category: category,
        sku: sku,
        baseUnit: baseUnit,
        notes: notes,
        trackStock: trackStock,
        stockQty: stockQty,
        lowStockThreshold: lowStockThreshold,
        packages: packages,
      );
      ref.invalidate(productsListProvider);
      ref.invalidate(productCategoriesProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateProduct({
    required String id,
    required String name,
    String? nameSw,
    required String category,
    String? sku,
    required String baseUnit,
    String? notes,
    required bool trackStock,
    required double lowStockThreshold,
    required List<ProductPackage> packages,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ProductRepository.instance.update(
        id: id,
        name: name,
        nameSw: nameSw,
        category: category,
        sku: sku,
        baseUnit: baseUnit,
        notes: notes,
        trackStock: trackStock,
        lowStockThreshold: lowStockThreshold,
        packages: packages,
      );
      ref.invalidate(productsListProvider);
      ref.invalidate(productCategoriesProvider);
      ref.invalidate(productByIdProvider(id));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> setActive(String id, bool active) async {
    try {
      await ProductRepository.instance.setActive(id, active);
      ref.invalidate(productsListProvider);
      ref.invalidate(productByIdProvider(id));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> restock(String id, double amount) async {
    try {
      await ProductRepository.instance.restock(id, amount);
      ref.invalidate(productsListProvider);
      ref.invalidate(productByIdProvider(id));
      return true;
    } catch (_) {
      return false;
    }
  }
}

final productsControllerProvider =
    NotifierProvider<ProductsController, AsyncValue<void>>(
      ProductsController.new,
    );
