import 'package:sqflite/sqflite.dart';
import '../../features/customers/models/customer.dart';
import '../../features/debts/models/debt.dart';
import '../local/app_database.dart';

class CustomerRepository {
  CustomerRepository._();
  static final CustomerRepository instance = CustomerRepository._();

  String _newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  Future<List<Customer>> getAll({
    bool activeOnly = true,
    String? search,
  }) async {
    final db = await AppDatabase.instance.database;

    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (activeOnly) whereClauses.add('active = 1');
    if (search != null && search.trim().isNotEmpty) {
      whereClauses.add('(name LIKE ? OR phone LIKE ? OR email LIKE ?)');
      final term = '%${search.trim()}%';
      whereArgs.addAll([term, term, term]);
    }

    final rows = await db.query(
      'customers',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Customer.fromRow).toList();
  }

  Future<Customer?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Customer.fromRow(rows.first);
  }

  /// The ONLY way to get a customer's total debt — always a live sum of
  /// non-settled debts' balances, never a stored/cached field. Per spec:
  /// a cached value drifted out of sync in the original system and was
  /// deliberately removed; this must stay computed, always.
  Future<double> getTotalDebt(String customerId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(balance), 0) as total FROM debts "
      "WHERE customer_id = ? AND status != 'settled'",
      [customerId],
    );
    final value = result.first['total'];
    return value is num ? value.toDouble() : 0;
  }

  /// Batches live total-debt lookups for a list of customers (e.g. the list
  /// screen), avoiding one query per row.
  Future<Map<String, double>> getTotalDebts(List<String> customerIds) async {
    if (customerIds.isEmpty) return {};
    final db = await AppDatabase.instance.database;
    final placeholders = List.filled(customerIds.length, '?').join(',');
    final rows = await db.rawQuery(
      "SELECT customer_id, COALESCE(SUM(balance), 0) as total FROM debts "
      "WHERE customer_id IN ($placeholders) AND status != 'settled' "
      "GROUP BY customer_id",
      customerIds,
    );
    final map = <String, double>{};
    for (final row in rows) {
      final id = row['customer_id'] as String;
      final total = row['total'];
      map[id] = total is num ? total.toDouble() : 0;
    }
    return map;
  }

  Future<List<Debt>> getDebtsForCustomer(String customerId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'debts',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Debt.fromRow).toList();
  }

  /// Batches non-settled debts for a list of customers in one query —
  /// used by the Debts overview screen to avoid one query per customer.
  Future<Map<String, List<Debt>>> getOpenDebtsForCustomers(
    List<String> customerIds,
  ) async {
    if (customerIds.isEmpty) return {};
    final db = await AppDatabase.instance.database;
    final placeholders = List.filled(customerIds.length, '?').join(',');
    final rows = await db.query(
      'debts',
      where: "customer_id IN ($placeholders) AND status != 'settled'",
      whereArgs: customerIds,
      orderBy: 'created_at DESC',
    );
    final map = <String, List<Debt>>{};
    for (final row in rows) {
      final debt = Debt.fromRow(row);
      map.putIfAbsent(debt.customerId, () => []).add(debt);
    }
    return map;
  }

  Future<List<DebtPayment>> getPaymentsForDebt(String debtId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'debt_payments',
      where: 'debt_id = ?',
      whereArgs: [debtId],
      orderBy: 'paid_at DESC',
    );
    return rows.map(DebtPayment.fromRow).toList();
  }

  Future<Customer> create({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    if (name.trim().isEmpty) {
      throw const CustomerValidationException('Name is required');
    }
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final customer = Customer(
      id: _newId('cust'),
      name: name.trim(),
      phone: (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
      email: (email?.trim().isEmpty ?? true) ? null : email!.trim(),
      address: (address?.trim().isEmpty ?? true) ? null : address!.trim(),
      notes: (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('customers', customer.toRow());
    return customer;
  }

  Future<Customer> update({
    required String id,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    if (name.trim().isEmpty) {
      throw const CustomerValidationException('Name is required');
    }
    final db = await AppDatabase.instance.database;
    await db.update(
      'customers',
      {
        'name': name.trim(),
        'phone': (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
        'email': (email?.trim().isEmpty ?? true) ? null : email!.trim(),
        'address': (address?.trim().isEmpty ?? true) ? null : address!.trim(),
        'notes': (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return (await getById(id))!;
  }

  /// Soft-delete, consistent with the products convention — keeps sale/debt
  /// history intact.
  Future<void> setActive(String id, bool active) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'customers',
      {
        'active': active ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Finds an existing active customer by exact (case-insensitive) name, or
  /// creates one. Used by New Sale when a walk-in customer name is typed
  /// and a debt needs to be attached to it (spec: never create a customer
  /// record for a walk-in that pays in full).
  Future<Customer> findOrCreateByName(String name) async {
    final db = await AppDatabase.instance.database;
    final trimmed = name.trim();
    final rows = await db.query(
      'customers',
      where: 'LOWER(name) = ? AND active = 1',
      whereArgs: [trimmed.toLowerCase()],
      limit: 1,
    );
    if (rows.isNotEmpty) return Customer.fromRow(rows.first);
    return create(name: trimmed);
  }

  /// Transaction-scoped twin of [findOrCreateByName] — must be used instead
  /// whenever this lookup happens as part of a larger atomic write (e.g.
  /// SaleRepository.completeSale), since the plain version opens its own
  /// implicit connection use and would break atomicity with the enclosing
  /// transaction.
  Future<Customer> findOrCreateByNameTxn(Transaction txn, String name) async {
    final trimmed = name.trim();
    final rows = await txn.query(
      'customers',
      where: 'LOWER(name) = ? AND active = 1',
      whereArgs: [trimmed.toLowerCase()],
      limit: 1,
    );
    if (rows.isNotEmpty) return Customer.fromRow(rows.first);

    final now = DateTime.now();
    final customer = Customer(
      id: _newId('cust'),
      name: trimmed,
      createdAt: now,
      updatedAt: now,
    );
    await txn.insert('customers', customer.toRow());
    return customer;
  }

  Future<void> incrementTotalPurchases(
    Transaction txn,
    String customerId,
    double amount,
  ) async {
    await txn.rawUpdate(
      'UPDATE customers SET total_purchases = total_purchases + ?, '
      'updated_at = ? WHERE id = ?',
      [amount, DateTime.now().toIso8601String(), customerId],
    );
  }

  /// Creates a debt row inside an enclosing transaction — used by
  /// SaleRepository.completeSale when a sale results in balance_due > 0.
  /// Status starts 'open' since nothing has been paid toward this specific
  /// debt yet (any amount already paid on the sale is reflected in the
  /// sale's own amount_paid, not this debt).
  Future<void> createDebtTxn(
    Transaction txn, {
    required String customerId,
    required String? saleId,
    required double amount,
  }) async {
    final now = DateTime.now();
    await txn.insert('debts', {
      'id': _newId('debt'),
      'customer_id': customerId,
      'sale_id': saleId,
      'original_amount': amount,
      'amount_paid': 0,
      'balance': amount,
      'status': DebtStatus.open.value,
      'due_date': null,
      'notes': null,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
  }

  /// Marks every non-settled debt linked to [saleId] as settled with a zero
  /// balance — used when voiding a sale (the debt is forgiven along with
  /// the sale, since the goods are no longer sold).
  Future<void> settleDebtsForVoidedSaleTxn(
    Transaction txn,
    String saleId,
  ) async {
    await txn.update(
      'debts',
      {
        'balance': 0,
        'status': DebtStatus.settled.value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: "sale_id = ? AND status != 'settled'",
      whereArgs: [saleId],
    );
  }

  /// Records a payment against a debt — translates the spec's payment logic
  /// exactly (Section 7). If the debt is linked to a sale, that sale's
  /// balance_due/payment_status are updated in the same transaction too.
  Future<void> recordDebtPayment({
    required String debtId,
    required double amount,
    PaymentMethod method = PaymentMethod.cash,
    String? note,
  }) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('debts', where: 'id = ?', whereArgs: [debtId]);
    if (rows.isEmpty) {
      throw const CustomerValidationException('Debt not found');
    }
    final debt = Debt.fromRow(rows.first);

    if (amount <= 0 || amount > debt.balance) {
      throw const CustomerValidationException(
        'Payment must be greater than zero and not exceed the balance',
      );
    }

    final newPaid = debt.amountPaid + amount;
    final newBalance = debt.balance - amount;
    final newStatus = newBalance <= 0 ? DebtStatus.settled : DebtStatus.partial;

    await db.transaction((txn) async {
      await txn.update(
        'debts',
        {
          'amount_paid': newPaid,
          'balance': newBalance,
          'status': newStatus.value,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [debtId],
      );
      await txn.insert('debt_payments', {
        'id': _newId('dpay'),
        'debt_id': debtId,
        'amount': amount,
        'method': method.value,
        'note': note,
        'paid_at': DateTime.now().toIso8601String(),
      });

      if (debt.saleId != null) {
        final saleRows = await txn.query(
          'sales',
          where: 'id = ?',
          whereArgs: [debt.saleId],
        );
        if (saleRows.isNotEmpty) {
          final currentBalanceDue = (saleRows.first['balance_due'] as num).toDouble();
          final newSaleBalanceDue = (currentBalanceDue - amount).clamp(0, double.infinity);
          await txn.update(
            'sales',
            {
              'balance_due': newSaleBalanceDue,
              'payment_status': newSaleBalanceDue <= 0 ? 'paid' : 'partial',
            },
            where: 'id = ?',
            whereArgs: [debt.saleId],
          );
        }
      }
    });
  }
}

class CustomerValidationException implements Exception {
  final String message;
  const CustomerValidationException(this.message);

  @override
  String toString() => message;
}
