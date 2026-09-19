import 'dart:math';
import 'package:sqflite/sqflite.dart';
import '../../core/utils/stock_math.dart';
import '../../core/utils/till_split.dart';
import '../../features/sales/models/cart_line.dart';
import '../../features/sales/models/sale.dart';
import 'app_database.dart';
import 'customer_repository.dart';
import 'product_repository.dart';

/// Result of a successful checkout — one Sale if the cart only touched one
/// till, or two linked Sales if it spanned both General and Drinks.
class CompletedSale {
  final Sale primary;
  final Sale? linked;

  const CompletedSale({required this.primary, this.linked});

  List<Sale> get all => linked == null ? [primary] : [primary, linked!];
}

class SaleRepository {
  SaleRepository._();
  static final SaleRepository instance = SaleRepository._();

  final _random = Random();

  String _newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  String _generateInvoiceNo(DateTime now) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final suffix = List.generate(5, (_) => chars[_random.nextInt(chars.length)]).join();
    final datePart =
        '${now.year.toString().substring(2)}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    return 'BZ-$datePart-$suffix';
  }

  /// Retries invoice generation on the rare UNIQUE collision rather than
  /// trusting randomness alone — five random alphanumeric chars gives ~60M
  /// combinations per day, so collisions are rare but not impossible.
  Future<String> _uniqueInvoiceNo(Transaction txn, DateTime now) async {
    for (var attempt = 0; attempt < 10; attempt++) {
      final candidate = _generateInvoiceNo(now);
      final existing = await txn.query(
        'sales',
        where: 'invoice_no = ?',
        whereArgs: [candidate],
        limit: 1,
      );
      if (existing.isEmpty) return candidate;
    }
    // Astronomically unlikely fallback: fall back to a fully unique id-based
    // suffix so checkout never hard-fails on this.
    return 'BZ-${now.millisecondsSinceEpoch}';
  }

  /// Validates every tracked-stock line in [cart] has enough stock *before*
  /// any writes happen. Returns the list of shortfalls (empty = all good).
  Future<List<StockShortfall>> validateStock(List<CartLine> cart) async {
    final trackedLines = cart
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

    final shortfalls = <StockShortfall>[];
    final productsById = {for (final l in cart) l.product.id: l.product};

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
  }

  /// Runs the full checkout: stock validation, atomic deduction, invoice
  /// generation, multi-till split, and debt auto-creation. Throws
  /// [SaleValidationException] (including StockShortfall details) if
  /// anything is invalid — nothing is written in that case.
  Future<CompletedSale> completeSale({
    required List<CartLine> cart,
    required double discount,
    required double amountPaid,
    required SalePaymentMethod paymentMethod,
    String? existingCustomerId,
    String? typedCustomerName,
    String? notes,
    String? createdByUserId,
  }) async {
    if (cart.isEmpty) {
      throw const SaleValidationException('Cart is empty');
    }
    if (cart.any((l) => l.needsPriceEntry)) {
      throw const SaleValidationException(
        'One or more negotiable items still need a price',
      );
    }
    if (discount < 0) {
      throw const SaleValidationException('Discount cannot be negative');
    }
    if (amountPaid < 0) {
      throw const SaleValidationException('Amount paid cannot be negative');
    }

    final shortfalls = await validateStock(cart);
    if (shortfalls.isNotEmpty) {
      throw SaleValidationException(shortfalls.first.message, shortfalls: shortfalls);
    }

    final subtotal = cart.fold<double>(0, (sum, l) => sum + l.lineTotal);
    if (discount > subtotal) {
      throw const SaleValidationException('Discount cannot exceed the subtotal');
    }
    final total = max(subtotal - discount, 0.0);

    final byTill = <Till, List<CartLine>>{};
    for (final line in cart) {
      byTill.putIfAbsent(line.till, () => []).add(line);
    }

    final db = await AppDatabase.instance.database;
    final now = DateTime.now();

    return db.transaction((txn) async {
      String? customerId = existingCustomerId;
      String customerName = 'Walk-in Customer';

      if (existingCustomerId != null) {
        final rows = await txn.query(
          'customers',
          where: 'id = ?',
          whereArgs: [existingCustomerId],
        );
        if (rows.isNotEmpty) customerName = rows.first['name'] as String;
      } else if (typedCustomerName != null && typedCustomerName.trim().isNotEmpty) {
        customerName = typedCustomerName.trim();
      }

      final neededByProduct = totalBaseUnitsNeededByProduct(
        cart
            .where((l) => l.product.trackStock)
            .map(
              (l) => (
                productId: l.product.id,
                packageBaseUnitQty: l.package.baseUnitQty,
                qty: l.qty,
              ),
            )
            .toList(),
      );
      for (final entry in neededByProduct.entries) {
        final ok = await ProductRepository.instance.deductStock(
          txn,
          entry.key,
          entry.value,
        );
        if (!ok) {
          final product = cart.firstWhere((l) => l.product.id == entry.key).product;
          throw SaleValidationException(
            StockShortfall(
              productId: product.id,
              productName: product.name,
              available: product.stockQty,
              requested: entry.value,
            ).message,
          );
        }
      }

      if (byTill.length <= 1) {
        final till = byTill.keys.first;
        final sale = await _insertSale(
          txn,
          now: now,
          till: till,
          lines: cart,
          subtotal: subtotal,
          discount: discount,
          total: total,
          amountPaid: amountPaid,
          paymentMethod: paymentMethod,
          customerId: customerId,
          customerName: customerName,
          notes: notes,
          linkedSaleId: null,
          createdByUserId: createdByUserId,
        );

        final finalCustomerId = await _handleCustomerAndDebtCombined(
          txn,
          primarySaleId: sale.id,
          combinedBalanceDue: sale.balanceDue,
          existingCustomerId: existingCustomerId,
          typedCustomerName: typedCustomerName,
          purchaseAmount: sale.total,
        );

        if (finalCustomerId != customerId) {
          await txn.update(
            'sales',
            {'customer_id': finalCustomerId},
            where: 'id = ?',
            whereArgs: [sale.id],
          );
        }

        return CompletedSale(primary: sale.withCustomerId(finalCustomerId));
      }

      // Multi-till split: two linked Sale rows, proportional split of
      // discount/paid by each till-group's subtotal weight.
      final tillOrder = byTill.keys.toList();
      final subtotalWeights = tillOrder
          .map((t) => MapEntry(t, byTill[t]!.fold<double>(0, (s, l) => s + l.lineTotal)))
          .toList();

      final discountShares = proportionalSplit(discount, subtotalWeights);
      final paidShares = proportionalSplit(amountPaid, subtotalWeights);

      final discountByTill = {for (final s in discountShares) s.till: s.share};
      final paidByTill = {for (final s in paidShares) s.till: s.share};

      Sale? first;
      Sale? second;

      for (final till in tillOrder) {
        final lines = byTill[till]!;
        final tillSubtotal = lines.fold<double>(0, (s, l) => s + l.lineTotal);
        final tillDiscount = discountByTill[till] ?? 0;
        final tillTotal = max(tillSubtotal - tillDiscount, 0.0);
        final tillPaid = paidByTill[till] ?? 0;

        final sale = await _insertSale(
          txn,
          now: now,
          till: till,
          lines: lines,
          subtotal: tillSubtotal,
          discount: tillDiscount,
          total: tillTotal,
          amountPaid: tillPaid,
          paymentMethod: paymentMethod,
          customerId: customerId,
          customerName: customerName,
          notes: notes,
          linkedSaleId: first?.id,
          createdByUserId: createdByUserId,
        );

        if (first == null) {
          first = sale;
        } else {
          second = sale;
          await txn.update(
            'sales',
            {'linked_sale_id': second.id},
            where: 'id = ?',
            whereArgs: [first.id],
          );
        }
      }

      final combinedBalanceDue = first!.balanceDue + (second?.balanceDue ?? 0);
      final combinedTotal = first.total + (second?.total ?? 0);
      final finalCustomerId = await _handleCustomerAndDebtCombined(
        txn,
        primarySaleId: first.id,
        combinedBalanceDue: combinedBalanceDue,
        existingCustomerId: existingCustomerId,
        typedCustomerName: typedCustomerName,
        purchaseAmount: combinedTotal,
      );

      if (finalCustomerId != customerId) {
        await txn.update(
          'sales',
          {'customer_id': finalCustomerId},
          where: 'id IN (?, ?)',
          whereArgs: [first.id, second!.id],
        );
      }

      first = first.withCustomerId(finalCustomerId).withLinked(second?.id);
      final finalSecond = second?.withCustomerId(finalCustomerId);

      return CompletedSale(primary: first, linked: finalSecond);
    });
  }

  Future<Sale> _insertSale(
    Transaction txn, {
    required DateTime now,
    required Till till,
    required List<CartLine> lines,
    required double subtotal,
    required double discount,
    required double total,
    required double amountPaid,
    required SalePaymentMethod paymentMethod,
    required String? customerId,
    required String customerName,
    required String? notes,
    required String? linkedSaleId,
    required String? createdByUserId,
  }) async {
    final change = max(amountPaid - total, 0.0);
    final balanceDue = max(total - amountPaid, 0.0);
    // 'debt' means nothing was paid toward an actual amount owed — a fully
    // discounted/free sale (total == 0) with amountPaid == 0 is 'paid',
    // not 'debt', since balanceDue is correctly 0 either way.
    final paymentStatus = balanceDue <= 0
        ? PaymentStatus.paid
        : (amountPaid <= 0 ? PaymentStatus.debt : PaymentStatus.partial);

    final saleId = _newId('sale');
    final invoiceNo = await _uniqueInvoiceNo(txn, now);

    final sale = Sale(
      id: saleId,
      invoiceNo: invoiceNo,
      customerId: customerId,
      customerName: customerName,
      subtotal: subtotal,
      discount: discount,
      total: total,
      amountPaid: amountPaid,
      change: change,
      balanceDue: balanceDue,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      notes: notes,
      voided: false,
      till: till,
      linkedSaleId: linkedSaleId,
      createdBy: createdByUserId,
      createdAt: now,
    );

    await txn.insert('sales', sale.toRow());

    final items = <SaleItem>[];
    for (final line in lines) {
      final itemId = _newId('sitem');
      final item = SaleItem(
        id: itemId,
        saleId: saleId,
        productId: line.product.id,
        productName: line.product.name,
        packageId: line.package.id,
        packageLabel: line.package.label,
        unitType: line.package.unitType,
        unitPrice: line.unitPrice,
        wasNegotiated: line.isNegotiable,
        baseUnitQty: line.package.baseUnitQty,
        trackStock: line.product.trackStock,
        qty: line.qty,
        lineTotal: line.lineTotal,
      );
      await txn.insert('sale_items', item.toRow());
      items.add(item);
    }

    return sale.withItems(items);
  }

  /// Resolves/creates the customer and, if `combinedBalanceDue > 0`,
  /// creates a debt and bumps total_purchases — exactly the spec's stated
  /// condition (Section 5, step 4): total_purchases only increments as
  /// part of the debt-creation branch, not for every sale with a customer
  /// attached. A customer who pays in full does not get total_purchases
  /// bumped by this path. Returns the final customer id used (or null for
  /// a pure walk-in with no debt).
  Future<String?> _handleCustomerAndDebtCombined(
    Transaction txn, {
    required String primarySaleId,
    required double combinedBalanceDue,
    required String? existingCustomerId,
    required String? typedCustomerName,
    required double purchaseAmount,
  }) async {
    if (combinedBalanceDue <= 0) {
      // No debt results from this sale — per spec, total_purchases and
      // customer auto-creation are only triggered by the debt branch.
      return existingCustomerId;
    }

    String? customerId = existingCustomerId;
    final hasTypedName = typedCustomerName != null && typedCustomerName.trim().isNotEmpty;

    if (customerId == null) {
      if (!hasTypedName) {
        // balance_due > 0 but no customer identified at all — this
        // shouldn't happen if the UI requires a customer whenever the cart
        // won't be paid in full, but guard defensively: no customer means
        // no debt can be tracked, so just leave it as a walk-in shortfall.
        return null;
      }
      final customer = await CustomerRepository.instance.findOrCreateByNameTxn(
        txn,
        typedCustomerName,
      );
      customerId = customer.id;
    }

    await CustomerRepository.instance.incrementTotalPurchases(
      txn,
      customerId,
      purchaseAmount,
    );

    await CustomerRepository.instance.createDebtTxn(
      txn,
      customerId: customerId,
      saleId: primarySaleId,
      amount: combinedBalanceDue,
    );

    return customerId;
  }

  Future<Sale?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('sales', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final itemRows = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [id],
    );
    return Sale.fromRow(
      rows.first,
      items: itemRows.map(SaleItem.fromRow).toList(),
    );
  }

  /// Voids a sale: restores stock for every tracked line (using the sale's
  /// own stored snapshot, not current product config), settles any linked
  /// debt, and marks the sale voided. If the sale has a linked till-split
  /// partner, both are voided together as one atomic unit — a multi-till
  /// checkout is one logical sale to the cashier and must void as one.
  Future<void> voidSale(String saleId) async {
    final db = await AppDatabase.instance.database;

    await db.transaction((txn) async {
      final saleRows = await txn.query('sales', where: 'id = ?', whereArgs: [saleId]);
      if (saleRows.isEmpty) {
        throw const SaleValidationException('Sale not found');
      }
      final sale = Sale.fromRow(saleRows.first);
      if (sale.voided) return;

      final idsToVoid = [saleId, if (sale.linkedSaleId != null) sale.linkedSaleId!];

      for (final id in idsToVoid) {
        final itemRows = await txn.query(
          'sale_items',
          where: 'sale_id = ?',
          whereArgs: [id],
        );
        for (final row in itemRows) {
          final item = SaleItem.fromRow(row);
          if (item.trackStock) {
            await ProductRepository.instance.restoreStock(
              txn,
              item.productId,
              item.baseUnitQty * item.qty,
            );
          }
        }

        await CustomerRepository.instance.settleDebtsForVoidedSaleTxn(txn, id);

        await txn.update(
          'sales',
          {'voided': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  Future<List<Sale>> getHistory({
    Till? till,
    PaymentStatus? paymentStatus,
    bool? voided,
    String? search,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await AppDatabase.instance.database;

    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (till != null) {
      whereClauses.add('till = ?');
      whereArgs.add(till.value);
    }
    if (paymentStatus != null) {
      whereClauses.add('payment_status = ?');
      whereArgs.add(paymentStatus.value);
    }
    if (voided != null) {
      whereClauses.add('voided = ?');
      whereArgs.add(voided ? 1 : 0);
    }
    if (search != null && search.trim().isNotEmpty) {
      whereClauses.add('(invoice_no LIKE ? OR customer_name LIKE ?)');
      final term = '%${search.trim()}%';
      whereArgs.addAll([term, term]);
    }
    if (from != null) {
      whereClauses.add('created_at >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      whereClauses.add('created_at <= ?');
      whereArgs.add(to.toIso8601String());
    }

    final rows = await db.query(
      'sales',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map((r) => Sale.fromRow(r)).toList();
  }
}

class SaleValidationException implements Exception {
  final String message;
  final List<StockShortfall> shortfalls;
  const SaleValidationException(this.message, {this.shortfalls = const []});

  @override
  String toString() => message;
}

extension SaleCopy on Sale {
  Sale withItems(List<SaleItem> items) => Sale(
    id: id,
    invoiceNo: invoiceNo,
    customerId: customerId,
    customerName: customerName,
    subtotal: subtotal,
    discount: discount,
    total: total,
    amountPaid: amountPaid,
    change: change,
    balanceDue: balanceDue,
    paymentStatus: paymentStatus,
    paymentMethod: paymentMethod,
    notes: notes,
    voided: voided,
    till: till,
    linkedSaleId: linkedSaleId,
    createdBy: createdBy,
    createdAt: createdAt,
    items: items,
  );

  Sale withCustomerId(String? customerId) => Sale(
    id: id,
    invoiceNo: invoiceNo,
    customerId: customerId,
    customerName: customerName,
    subtotal: subtotal,
    discount: discount,
    total: total,
    amountPaid: amountPaid,
    change: change,
    balanceDue: balanceDue,
    paymentStatus: paymentStatus,
    paymentMethod: paymentMethod,
    notes: notes,
    voided: voided,
    till: till,
    linkedSaleId: linkedSaleId,
    createdBy: createdBy,
    createdAt: createdAt,
    items: items,
  );

  Sale withLinked(String? linkedSaleId) => Sale(
    id: id,
    invoiceNo: invoiceNo,
    customerId: customerId,
    customerName: customerName,
    subtotal: subtotal,
    discount: discount,
    total: total,
    amountPaid: amountPaid,
    change: change,
    balanceDue: balanceDue,
    paymentStatus: paymentStatus,
    paymentMethod: paymentMethod,
    notes: notes,
    voided: voided,
    till: till,
    linkedSaleId: linkedSaleId ?? this.linkedSaleId,
    createdBy: createdBy,
    createdAt: createdAt,
    items: items,
  );
}
