import '../../../core/utils/till_split.dart';
import '../../products/models/product.dart';

/// One line in the in-progress cart. Distinct from [SaleItem] because a
/// cart line still points at live Product/ProductPackage objects (so price
/// and stock context stay current while shopping); it's only converted to
/// immutable SaleItem snapshots at checkout.
class CartLine {
  final String id;
  final Product product;
  final ProductPackage package;
  final double qty;

  /// Set when this package is negotiable and a price was entered/confirmed
  /// for this specific line. Null means "not yet priced" for a negotiable
  /// package — such a line can't be checked out until this is set.
  final double? negotiatedPrice;

  const CartLine({
    required this.id,
    required this.product,
    required this.package,
    required this.qty,
    this.negotiatedPrice,
  });

  bool get isNegotiable => package.pricingType == PricingType.negotiable;
  bool get needsPriceEntry => isNegotiable && negotiatedPrice == null;

  double get unitPrice =>
      isNegotiable ? (negotiatedPrice ?? 0) : (package.price ?? 0);

  double get lineTotal => unitPrice * qty;

  double get baseUnitsNeeded => package.baseUnitQty * qty;

  Till get till => tillForCategory(product.category);

  CartLine copyWith({double? qty, double? negotiatedPrice}) {
    return CartLine(
      id: id,
      product: product,
      package: package,
      qty: qty ?? this.qty,
      negotiatedPrice: negotiatedPrice ?? this.negotiatedPrice,
    );
  }
}
