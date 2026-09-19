/// How much of a tracked product's `stock_qty` a single cart line consumes.
/// E.g. a 500g package with `base_unit_qty = 0.5` and qty 3 consumes 1.5 of
/// the product's base unit (kg).
double baseUnitsNeeded({required double packageBaseUnitQty, required double qty}) {
  return packageBaseUnitQty * qty;
}

/// Sums base-units-needed per product across a whole cart, for the
/// before-checkout stock validation pass. Only tracked products should be
/// passed in by the caller — untracked (`track_stock = false`) products are
/// unlimited and never participate in this check.
Map<String, double> totalBaseUnitsNeededByProduct(
  List<({String productId, double packageBaseUnitQty, double qty})> lines,
) {
  final totals = <String, double>{};
  for (final line in lines) {
    final needed = baseUnitsNeeded(
      packageBaseUnitQty: line.packageBaseUnitQty,
      qty: line.qty,
    );
    totals.update(line.productId, (v) => v + needed, ifAbsent: () => needed);
  }
  return totals;
}

/// A stock shortfall found during pre-checkout validation.
class StockShortfall {
  final String productId;
  final String productName;
  final double available;
  final double requested;

  const StockShortfall({
    required this.productId,
    required this.productName,
    required this.available,
    required this.requested,
  });

  String get message =>
      'Not enough stock for $productName: $available available, $requested requested.';
}
