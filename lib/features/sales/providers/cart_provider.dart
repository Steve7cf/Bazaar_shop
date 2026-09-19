import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/stock_math.dart';
import '../../../core/utils/till_split.dart';
import '../../../data/local/session_storage.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../customers/providers/customers_provider.dart';
import '../../debts/providers/debts_provider.dart';
import '../../products/models/product.dart';
import '../../products/providers/products_provider.dart';
import '../models/cart_line.dart';
import '../models/sale.dart';

/// Everything the New Sale screen needs about the current in-progress cart.
class CartState {
  final List<CartLine> lines;
  final String? selectedCustomerId;
  final String typedCustomerName;
  final double discount;
  final double amountPaid;
  final SalePaymentMethod paymentMethod;
  final String? notes;

  const CartState({
    this.lines = const [],
    this.selectedCustomerId,
    this.typedCustomerName = '',
    this.discount = 0,
    this.amountPaid = 0,
    this.paymentMethod = SalePaymentMethod.cash,
    this.notes,
  });

  double get subtotal => lines.fold(0.0, (sum, l) => sum + l.lineTotal);
  double get total => (subtotal - discount).clamp(0, double.infinity);
  double get change => (amountPaid - total).clamp(0, double.infinity);
  double get balanceDue => (total - amountPaid).clamp(0, double.infinity);

  bool get isEmpty => lines.isEmpty;
  bool get hasPendingNegotiation => lines.any((l) => l.needsPriceEntry);

  /// True once the cart spans both General and Drinks — the UI shows the
  /// info banner and checkout will produce two linked sales.
  bool get spansMultipleTills =>
      lines.map((l) => l.till).toSet().length > 1;

  /// Complete Sale is disabled until the cart is non-empty and every
  /// negotiable line has a confirmed price — mirrors the original's
  /// disabled-by-default checkout button.
  bool get canCheckout => !isEmpty && !hasPendingNegotiation;

  CartState copyWith({
    List<CartLine>? lines,
    String? selectedCustomerId,
    bool clearSelectedCustomer = false,
    String? typedCustomerName,
    double? discount,
    double? amountPaid,
    SalePaymentMethod? paymentMethod,
    String? notes,
  }) {
    return CartState(
      lines: lines ?? this.lines,
      selectedCustomerId: clearSelectedCustomer
          ? null
          : (selectedCustomerId ?? this.selectedCustomerId),
      typedCustomerName: typedCustomerName ?? this.typedCustomerName,
      discount: discount ?? this.discount,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  /// Adds one unit of [package] to the cart. If an identical (same product
  /// + package + same negotiated price context) non-negotiable line already
  /// exists, bumps its qty instead of creating a duplicate row. Negotiable
  /// packages always create a fresh line, since each add is a fresh
  /// negotiation per the spec's per-line was_negotiated model — merging
  /// them would silently apply one line's price to another's quantity.
  void addLine(Product product, ProductPackage package) {
    if (package.pricingType == PricingType.negotiable) {
      state = state.copyWith(
        lines: [
          ...state.lines,
          CartLine(
            id: 'line_${DateTime.now().microsecondsSinceEpoch}',
            product: product,
            package: package,
            qty: 1,
          ),
        ],
      );
      return;
    }

    final existingIndex = state.lines.indexWhere(
      (l) => l.product.id == product.id && l.package.id == package.id,
    );
    if (existingIndex != -1) {
      final existing = state.lines[existingIndex];
      final updated = [...state.lines];
      updated[existingIndex] = existing.copyWith(qty: existing.qty + 1);
      state = state.copyWith(lines: updated);
      return;
    }

    state = state.copyWith(
      lines: [
        ...state.lines,
        CartLine(
          id: 'line_${DateTime.now().microsecondsSinceEpoch}',
          product: product,
          package: package,
          qty: 1,
        ),
      ],
    );
  }

  /// Sets the confirmed price for a negotiable line that was just added —
  /// validates it falls within [min_price, max_price] inclusive.
  String? setNegotiatedPrice(String lineId, double price) {
    final index = state.lines.indexWhere((l) => l.id == lineId);
    if (index == -1) return 'Line not found';

    final line = state.lines[index];
    final min = line.package.minPrice ?? 0;
    final max = line.package.maxPrice ?? 0;
    if (price < min || price > max) {
      return 'Price must be between ${min.toStringAsFixed(0)} and ${max.toStringAsFixed(0)}';
    }

    final updated = [...state.lines];
    updated[index] = line.copyWith(negotiatedPrice: price);
    state = state.copyWith(lines: updated);
    return null;
  }

  void updateQty(String lineId, double qty) {
    if (qty <= 0) {
      removeLine(lineId);
      return;
    }
    final updated = state.lines
        .map((l) => l.id == lineId ? l.copyWith(qty: qty) : l)
        .toList();
    state = state.copyWith(lines: updated);
  }

  void removeLine(String lineId) {
    state = state.copyWith(
      lines: state.lines.where((l) => l.id != lineId).toList(),
    );
  }

  void selectCustomer(String? customerId) {
    state = customerId == null
        ? state.copyWith(clearSelectedCustomer: true, typedCustomerName: '')
        : state.copyWith(
            selectedCustomerId: customerId,
            typedCustomerName: '',
          );
  }

  void setTypedCustomerName(String name) {
    state = state.copyWith(
      typedCustomerName: name,
      clearSelectedCustomer: true,
    );
  }

  void setDiscount(double discount) {
    state = state.copyWith(discount: discount < 0 ? 0 : discount);
  }

  void setAmountPaid(double amount) {
    state = state.copyWith(amountPaid: amount < 0 ? 0 : amount);
  }

  void setPaymentMethod(SalePaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void reset() {
    state = const CartState();
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

/// Live per-line stock check — flags cart lines that would exceed available
/// stock right now, so the UI can warn before the user even attempts
/// checkout (the repository still re-validates atomically at commit time
/// regardless, this is just an early, friendlier signal).
final cartStockShortfallsProvider = Provider<List<StockShortfall>>((ref) {
  final cart = ref.watch(cartProvider);
  final trackedLines = cart.lines
      .where((l) => l.product.trackStock)
      .map(
        (l) => (
          productId: l.product.id,
          packageBaseUnitQty: l.package.baseUnitQty,
          qty: l.qty,
        ),
      )
      .toList();

  final needed = totalBaseUnitsNeededByProduct(trackedLines);
  if (needed.isEmpty) return const [];

  final productsById = {for (final l in cart.lines) l.product.id: l.product};
  final shortfalls = <StockShortfall>[];
  for (final entry in needed.entries) {
    final product = productsById[entry.key];
    if (product == null) continue;
    if (product.stockQty < entry.value) {
      shortfalls.add(
        StockShortfall(
          productId: product.id,
          productName: product.name,
          available: product.stockQty,
          requested: entry.value,
        ),
      );
    }
  }
  return shortfalls;
});

class CheckoutController extends Notifier<AsyncValue<CompletedSale?>> {
  @override
  AsyncValue<CompletedSale?> build() => const AsyncValue.data(null);

  Future<CompletedSale?> checkout() async {
    final cart = ref.read(cartProvider);

    if (!cart.canCheckout) {
      state = AsyncValue.error(
        const SaleValidationException('Cart is empty or has unpriced items'),
        StackTrace.current,
      );
      return null;
    }

    state = const AsyncValue.loading();
    try {
      final userId = await SessionStorage.instance.getUserId();
      final result = await SaleRepository.instance.completeSale(
        cart: cart.lines,
        discount: cart.discount,
        amountPaid: cart.amountPaid,
        paymentMethod: cart.paymentMethod,
        existingCustomerId: cart.selectedCustomerId,
        typedCustomerName: cart.typedCustomerName.trim().isEmpty
            ? null
            : cart.typedCustomerName.trim(),
        notes: cart.notes,
        createdByUserId: userId,
      );

      // Refresh everything this checkout could have affected.
      ref.invalidate(productsListProvider);
      ref.invalidate(customersListProvider);
      ref.invalidate(customerDebtTotalsProvider);
      ref.invalidate(debtsOverviewProvider);

      state = AsyncValue.data(result);
      ref.read(cartProvider.notifier).reset();
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void clearResult() {
    state = const AsyncValue.data(null);
  }
}

final checkoutControllerProvider =
    NotifierProvider<CheckoutController, AsyncValue<CompletedSale?>>(
      CheckoutController.new,
    );

/// Product search/category state, mirrors ProductsFilter but scoped to the
/// New Sale grid so it doesn't interfere with the Products screen's own
/// filter state.
class SaleProductFilter {
  final String search;
  final String? category;
  const SaleProductFilter({this.search = '', this.category});

  SaleProductFilter copyWith({
    String? search,
    String? category,
    bool clearCategory = false,
  }) {
    return SaleProductFilter(
      search: search ?? this.search,
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}

class SaleProductFilterNotifier extends Notifier<SaleProductFilter> {
  @override
  SaleProductFilter build() => const SaleProductFilter();

  void setSearch(String value) => state = state.copyWith(search: value);

  void setCategory(String? category) {
    state = category == null
        ? state.copyWith(clearCategory: true)
        : state.copyWith(category: category);
  }
}

final saleProductFilterProvider =
    NotifierProvider<SaleProductFilterNotifier, SaleProductFilter>(
      SaleProductFilterNotifier.new,
    );

/// Active products for the New Sale grid, filtered client-side by the
/// screen's own search/category state (loaded once per screen open, per
/// spec step 1 — re-filtering in memory rather than re-querying keeps the
/// grid responsive while typing).
final saleProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  return ProductRepository.instance.getAll();
});

final filteredSaleProductsProvider = Provider.autoDispose<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(saleProductsProvider);
  final filter = ref.watch(saleProductFilterProvider);

  return productsAsync.whenData((products) {
    var result = products;
    if (filter.category != null) {
      result = result.where((p) => p.category == filter.category).toList();
    }
    if (filter.search.trim().isNotEmpty) {
      final term = filter.search.trim().toLowerCase();
      result = result
          .where(
            (p) =>
                p.name.toLowerCase().contains(term) ||
                (p.nameSw?.toLowerCase().contains(term) ?? false),
          )
          .toList();
    }
    return result;
  });
});
