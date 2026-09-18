import 'package:sqflite/sqflite.dart';
import '../../features/products/models/product.dart';
import '../local/app_database.dart';

class ProductRepository {
  ProductRepository._();
  static final ProductRepository instance = ProductRepository._();

  String _newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  /// Loads products (active-only by default) with their packages attached.
  /// Matches on name/name_sw/sku when [search] is given, and filters by
  /// exact category when [category] is given.
  Future<List<Product>> getAll({
    bool activeOnly = true,
    String? search,
    String? category,
  }) async {
    final db = await AppDatabase.instance.database;

    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (activeOnly) {
      whereClauses.add('active = 1');
    }
    if (category != null && category.trim().isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }
    if (search != null && search.trim().isNotEmpty) {
      whereClauses.add('(name LIKE ? OR name_sw LIKE ? OR sku LIKE ?)');
      final term = '%${search.trim()}%';
      whereArgs.addAll([term, term, term]);
    }

    final rows = await db.query(
      'products',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name COLLATE NOCASE ASC',
    );

    if (rows.isEmpty) return [];

    final ids = rows.map((r) => r['id'] as String).toList();
    final packagesByProduct = await _packagesForProductIds(db, ids);

    return rows
        .map(
          (row) => Product.fromRow(
            row,
            packages: packagesByProduct[row['id'] as String] ?? const [],
          ),
        )
        .toList();
  }

  Future<Map<String, List<ProductPackage>>> _packagesForProductIds(
    Database db,
    List<String> productIds,
  ) async {
    if (productIds.isEmpty) return {};
    final placeholders = List.filled(productIds.length, '?').join(',');
    final rows = await db.query(
      'product_packages',
      where: 'product_id IN ($placeholders) AND active = 1',
      whereArgs: productIds,
      orderBy: 'label COLLATE NOCASE ASC',
    );
    final map = <String, List<ProductPackage>>{};
    for (final row in rows) {
      final pkg = ProductPackage.fromRow(row);
      map.putIfAbsent(pkg.productId, () => []).add(pkg);
    }
    return map;
  }

  Future<Product?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final packages = await _packagesForProductIds(db, [id]);
    return Product.fromRow(rows.first, packages: packages[id] ?? const []);
  }

  Future<List<String>> getCategories() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT category FROM products WHERE active = 1 '
      'ORDER BY category COLLATE NOCASE ASC',
    );
    return rows.map((r) => r['category'] as String).toList();
  }

  /// Creates a product together with its packages, in a single transaction.
  Future<Product> create({
    required String name,
    String? nameSw,
    required String category,
    String? sku,
    required String baseUnit,
    String? imagePath,
    String? notes,
    required bool trackStock,
    required double stockQty,
    required double lowStockThreshold,
    required List<ProductPackage> packages,
  }) async {
    for (final pkg in packages) {
      final error = pkg.validate();
      if (error != null) throw ProductValidationException(error);
    }
    if (packages.isEmpty) {
      throw const ProductValidationException(
        'Add at least one package/pricing option',
      );
    }

    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final productId = _newId('prod');

    final product = Product(
      id: productId,
      name: name.trim(),
      nameSw: (nameSw?.trim().isEmpty ?? true) ? null : nameSw!.trim(),
      category: category.trim().isEmpty ? 'General' : category.trim(),
      sku: (sku?.trim().isEmpty ?? true) ? null : sku!.trim(),
      baseUnit: baseUnit.trim().isEmpty ? 'kg' : baseUnit.trim(),
      imagePath: imagePath,
      active: true,
      notes: (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
      trackStock: trackStock,
      stockQty: trackStock ? stockQty : 0,
      lowStockThreshold: lowStockThreshold,
      createdAt: now,
      updatedAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert('products', product.toRow());
      for (final pkg in packages) {
        final row = pkg
            .copyWith(id: _newId('pkg'), productId: productId)
            .toRow();
        await txn.insert('product_packages', row);
      }
    });

    return (await getById(productId))!;
  }

  /// Replaces a product's core fields and its full package set. Existing
  /// packages not present in [packages] are soft-deactivated rather than
  /// deleted, so historical sale_items snapshots referencing them stay
  /// intact.
  Future<Product> update({
    required String id,
    required String name,
    String? nameSw,
    required String category,
    String? sku,
    required String baseUnit,
    String? imagePath,
    String? notes,
    required bool trackStock,
    required double lowStockThreshold,
    required List<ProductPackage> packages,
  }) async {
    for (final pkg in packages) {
      final error = pkg.validate();
      if (error != null) throw ProductValidationException(error);
    }
    if (packages.isEmpty) {
      throw const ProductValidationException(
        'Add at least one package/pricing option',
      );
    }

    final db = await AppDatabase.instance.database;
    final existing = await getById(id);
    if (existing == null) {
      throw const ProductValidationException('Product not found');
    }

    final keepIds = packages
        .where((p) => !p.id.startsWith('new_'))
        .map((p) => p.id)
        .toSet();

    await db.transaction((txn) async {
      await txn.update(
        'products',
        {
          'name': name.trim(),
          'name_sw': (nameSw?.trim().isEmpty ?? true) ? null : nameSw!.trim(),
          'category': category.trim().isEmpty ? 'General' : category.trim(),
          'sku': (sku?.trim().isEmpty ?? true) ? null : sku!.trim(),
          'base_unit': baseUnit.trim().isEmpty ? 'kg' : baseUnit.trim(),
          'image_path': imagePath,
          'notes': (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
          'track_stock': trackStock ? 1 : 0,
          'low_stock_threshold': lowStockThreshold,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      // Deactivate packages that were removed in this edit.
      final existingIds = existing.packages.map((p) => p.id).toSet();
      final removedIds = existingIds.difference(keepIds);
      for (final pkgId in removedIds) {
        await txn.update(
          'product_packages',
          {'active': 0},
          where: 'id = ?',
          whereArgs: [pkgId],
        );
      }

      for (final pkg in packages) {
        if (pkg.id.startsWith('new_')) {
          await txn.insert(
            'product_packages',
            pkg.copyWith(id: _newId('pkg'), productId: id).toRow(),
          );
        } else {
          await txn.update(
            'product_packages',
            pkg.copyWith(productId: id).toRow(),
            where: 'id = ?',
            whereArgs: [pkg.id],
          );
        }
      }
    });

    return (await getById(id))!;
  }

  /// Soft-delete — never hard-delete a product, per spec.
  Future<void> setActive(String id, bool active) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'products',
      {'active': active ? 1 : 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Adds [amount] to stock_qty (restock dialog). No-op for track_stock=false
  /// products, per spec — they're exempt from all stock math.
  Future<void> restock(String id, double amount) async {
    if (amount <= 0) {
      throw const ProductValidationException(
        'Restock amount must be greater than zero',
      );
    }
    final db = await AppDatabase.instance.database;
    final product = await getById(id);
    if (product == null || !product.trackStock) return;

    await db.rawUpdate(
      'UPDATE products SET stock_qty = stock_qty + ?, updated_at = ? WHERE id = ?',
      [amount, DateTime.now().toIso8601String(), id],
    );
  }

  /// Atomic guarded decrement for sale completion — re-checks stock_qty
  /// inside the same statement so a concurrent edit can't push it negative.
  /// Returns false if there wasn't enough stock (caller should abort/rollback
  /// the whole sale transaction in that case).
  Future<bool> deductStock(
    Transaction txn,
    String productId,
    double baseUnitsNeeded,
  ) async {
    final count = await txn.rawUpdate(
      'UPDATE products SET stock_qty = stock_qty - ?, updated_at = ? '
      'WHERE id = ? AND track_stock = 1 AND stock_qty >= ?',
      [
        baseUnitsNeeded,
        DateTime.now().toIso8601String(),
        productId,
        baseUnitsNeeded,
      ],
    );
    return count > 0;
  }

  /// Reverses a stock deduction when a sale is voided. Uses the sale's own
  /// stored line item quantities (never re-derives from current product
  /// config), matching the "void must restore exactly what was deducted"
  /// rule.
  Future<void> restoreStock(
    Transaction txn,
    String productId,
    double baseUnitsToRestore,
  ) async {
    await txn.rawUpdate(
      'UPDATE products SET stock_qty = stock_qty + ?, updated_at = ? '
      'WHERE id = ? AND track_stock = 1',
      [baseUnitsToRestore, DateTime.now().toIso8601String(), productId],
    );
  }

  Future<List<Product>> getLowStock() async {
    final all = await getAll();
    return all.where((p) => p.isLowStock || p.isOutOfStock).toList()
      ..sort((a, b) => a.stockQty.compareTo(b.stockQty));
  }
}

class ProductValidationException implements Exception {
  final String message;
  const ProductValidationException(this.message);

  @override
  String toString() => message;
}
