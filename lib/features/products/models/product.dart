enum PricingType { fixed, negotiable }

extension PricingTypeValue on PricingType {
  String get value => switch (this) {
    PricingType.fixed => 'fixed',
    PricingType.negotiable => 'negotiable',
  };

  static PricingType fromValue(String? v) =>
      v == 'negotiable' ? PricingType.negotiable : PricingType.fixed;
}

/// A sellable package/size of a product, e.g. "1kg", "500g", "gorogoro tin".
class ProductPackage {
  final String id;
  final String productId;
  final String label;
  final String unitType;
  final PricingType pricingType;

  /// For fixed pricing: the price charged. For negotiable pricing: mirrors
  /// [maxPrice] (kept in sync), matching the original schema's note that the
  /// max is also stored here.
  final double? price;
  final double? minPrice;
  final double? maxPrice;

  /// How many base_units of the parent product this package consumes,
  /// e.g. a "500g" package on a kg-tracked product has base_unit_qty 0.5.
  final double baseUnitQty;
  final bool active;

  const ProductPackage({
    required this.id,
    required this.productId,
    required this.label,
    required this.unitType,
    required this.pricingType,
    this.price,
    this.minPrice,
    this.maxPrice,
    this.baseUnitQty = 1,
    this.active = true,
  });

  /// Mirrors the original Mongoose `pre('validate')` hook: negotiable
  /// packages must have both bounds set, with min <= max.
  String? validate() {
    if (label.trim().isEmpty) return 'Package label is required';
    if (unitType.trim().isEmpty) return 'Unit type is required';

    if (pricingType == PricingType.fixed) {
      if (price == null || price! <= 0) {
        return '"$label": a fixed price is required';
      }
    } else {
      if (minPrice == null || maxPrice == null) {
        return '"$label": negotiable packages need both min and max price';
      }
      if (minPrice! <= 0 || maxPrice! <= 0) {
        return '"$label": prices must be greater than zero';
      }
      if (minPrice! > maxPrice!) {
        return '"$label": min price cannot exceed max price';
      }
    }

    if (baseUnitQty <= 0) {
      return '"$label": base unit quantity must be greater than zero';
    }
    return null;
  }

  /// The price to show in listings — for negotiable packages, the range.
  double get displayPrice =>
      pricingType == PricingType.fixed ? (price ?? 0) : (maxPrice ?? 0);

  ProductPackage copyWith({
    String? id,
    String? productId,
    String? label,
    String? unitType,
    PricingType? pricingType,
    double? price,
    double? minPrice,
    double? maxPrice,
    double? baseUnitQty,
    bool? active,
  }) {
    return ProductPackage(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      label: label ?? this.label,
      unitType: unitType ?? this.unitType,
      pricingType: pricingType ?? this.pricingType,
      price: price ?? this.price,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      baseUnitQty: baseUnitQty ?? this.baseUnitQty,
      active: active ?? this.active,
    );
  }

  factory ProductPackage.fromRow(Map<String, Object?> row) {
    return ProductPackage(
      id: row['id'] as String,
      productId: row['product_id'] as String,
      label: row['label'] as String,
      unitType: row['unit_type'] as String,
      pricingType: PricingTypeValue.fromValue(row['pricing_type'] as String?),
      price: (row['price'] as num?)?.toDouble(),
      minPrice: (row['min_price'] as num?)?.toDouble(),
      maxPrice: (row['max_price'] as num?)?.toDouble(),
      baseUnitQty: (row['base_unit_qty'] as num?)?.toDouble() ?? 1,
      active: (row['active'] as int? ?? 1) == 1,
    );
  }

  Map<String, Object?> toRow() => {
    'id': id,
    'product_id': productId,
    'label': label,
    'unit_type': unitType,
    'pricing_type': pricingType.value,
    'price': pricingType == PricingType.negotiable ? maxPrice : price,
    'min_price': minPrice,
    'max_price': maxPrice,
    'base_unit_qty': baseUnitQty,
    'active': active ? 1 : 0,
  };
}

class Product {
  final String id;
  final String name;
  final String? nameSw;
  final String category;
  final String? sku;
  final String baseUnit;
  final String? imagePath;
  final bool active;
  final String? notes;
  final bool trackStock;
  final double stockQty;
  final double lowStockThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProductPackage> packages;

  const Product({
    required this.id,
    required this.name,
    this.nameSw,
    this.category = 'General',
    this.sku,
    this.baseUnit = 'kg',
    this.imagePath,
    this.active = true,
    this.notes,
    this.trackStock = true,
    this.stockQty = 0,
    this.lowStockThreshold = 5,
    required this.createdAt,
    required this.updatedAt,
    this.packages = const [],
  });

  /// A product with no tracked stock is exempt from stock math entirely —
  /// it's neither "low" nor "out" no matter what stockQty says.
  bool get isOutOfStock => trackStock && stockQty <= 0;

  bool get isLowStock =>
      trackStock && stockQty > 0 && stockQty <= lowStockThreshold;

  Product copyWith({
    String? name,
    String? nameSw,
    String? category,
    String? sku,
    String? baseUnit,
    String? imagePath,
    bool? active,
    String? notes,
    bool? trackStock,
    double? stockQty,
    double? lowStockThreshold,
    DateTime? updatedAt,
    List<ProductPackage>? packages,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      nameSw: nameSw ?? this.nameSw,
      category: category ?? this.category,
      sku: sku ?? this.sku,
      baseUnit: baseUnit ?? this.baseUnit,
      imagePath: imagePath ?? this.imagePath,
      active: active ?? this.active,
      notes: notes ?? this.notes,
      trackStock: trackStock ?? this.trackStock,
      stockQty: stockQty ?? this.stockQty,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      packages: packages ?? this.packages,
    );
  }

  factory Product.fromRow(
    Map<String, Object?> row, {
    List<ProductPackage> packages = const [],
  }) {
    return Product(
      id: row['id'] as String,
      name: row['name'] as String,
      nameSw: row['name_sw'] as String?,
      category: (row['category'] as String?) ?? 'General',
      sku: row['sku'] as String?,
      baseUnit: (row['base_unit'] as String?) ?? 'kg',
      imagePath: row['image_path'] as String?,
      active: (row['active'] as int? ?? 1) == 1,
      notes: row['notes'] as String?,
      trackStock: (row['track_stock'] as int? ?? 1) == 1,
      stockQty: (row['stock_qty'] as num?)?.toDouble() ?? 0,
      lowStockThreshold: (row['low_stock_threshold'] as num?)?.toDouble() ?? 5,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      packages: packages,
    );
  }

  Map<String, Object?> toRow() => {
    'id': id,
    'name': name,
    'name_sw': nameSw,
    'category': category,
    'sku': sku,
    'base_unit': baseUnit,
    'image_path': imagePath,
    'active': active ? 1 : 0,
    'notes': notes,
    'track_stock': trackStock ? 1 : 0,
    'stock_qty': stockQty,
    'low_stock_threshold': lowStockThreshold,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
