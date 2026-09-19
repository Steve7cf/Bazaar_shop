import '../../../core/utils/till_split.dart';

enum PaymentStatus { paid, partial, debt }

extension PaymentStatusValue on PaymentStatus {
  String get value => switch (this) {
    PaymentStatus.paid => 'paid',
    PaymentStatus.partial => 'partial',
    PaymentStatus.debt => 'debt',
  };

  static PaymentStatus fromValue(String? v) => switch (v) {
    'partial' => PaymentStatus.partial,
    'debt' => PaymentStatus.debt,
    _ => PaymentStatus.paid,
  };
}

enum SalePaymentMethod { cash, mobile, bank, other }

extension SalePaymentMethodValue on SalePaymentMethod {
  String get value => switch (this) {
    SalePaymentMethod.cash => 'cash',
    SalePaymentMethod.mobile => 'mobile',
    SalePaymentMethod.bank => 'bank',
    SalePaymentMethod.other => 'other',
  };

  String get label => switch (this) {
    SalePaymentMethod.cash => 'Cash',
    SalePaymentMethod.mobile => 'Mobile Money',
    SalePaymentMethod.bank => 'Bank Transfer',
    SalePaymentMethod.other => 'Other',
  };

  static SalePaymentMethod fromValue(String? v) => switch (v) {
    'mobile' => SalePaymentMethod.mobile,
    'bank' => SalePaymentMethod.bank,
    'other' => SalePaymentMethod.other,
    _ => SalePaymentMethod.cash,
  };
}

class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final String? packageId;
  final String packageLabel;
  final String unitType;

  /// The actual price charged — may differ from the package's own price if
  /// this line was negotiated.
  final double unitPrice;
  final bool wasNegotiated;

  /// Snapshots of the package/product config at sale time, so a void can
  /// restore stock correctly even if the product has since been edited.
  final double baseUnitQty;
  final bool trackStock;

  final double qty;
  final double lineTotal;

  const SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    this.packageId,
    required this.packageLabel,
    required this.unitType,
    required this.unitPrice,
    this.wasNegotiated = false,
    required this.baseUnitQty,
    required this.trackStock,
    required this.qty,
    required this.lineTotal,
  });

  factory SaleItem.fromRow(Map<String, Object?> row) {
    return SaleItem(
      id: row['id'] as String,
      saleId: row['sale_id'] as String,
      productId: row['product_id'] as String,
      productName: row['product_name'] as String,
      packageId: row['package_id'] as String?,
      packageLabel: row['package_label'] as String,
      unitType: row['unit_type'] as String,
      unitPrice: (row['unit_price'] as num).toDouble(),
      wasNegotiated: (row['was_negotiated'] as int? ?? 0) == 1,
      baseUnitQty: (row['base_unit_qty'] as num?)?.toDouble() ?? 1,
      trackStock: (row['track_stock'] as int? ?? 1) == 1,
      qty: (row['qty'] as num).toDouble(),
      lineTotal: (row['line_total'] as num).toDouble(),
    );
  }

  Map<String, Object?> toRow() => {
    'id': id,
    'sale_id': saleId,
    'product_id': productId,
    'product_name': productName,
    'package_id': packageId,
    'package_label': packageLabel,
    'unit_type': unitType,
    'unit_price': unitPrice,
    'was_negotiated': wasNegotiated ? 1 : 0,
    'base_unit_qty': baseUnitQty,
    'track_stock': trackStock ? 1 : 0,
    'qty': qty,
    'line_total': lineTotal,
  };
}

class Sale {
  final String id;
  final String invoiceNo;
  final String? customerId;
  final String customerName;
  final double subtotal;
  final double discount;
  final double total;
  final double amountPaid;
  final double change;
  final double balanceDue;
  final PaymentStatus paymentStatus;
  final SalePaymentMethod paymentMethod;
  final String? notes;
  final bool voided;
  final Till till;
  final String? linkedSaleId;
  final String? createdBy;
  final DateTime createdAt;
  final List<SaleItem> items;

  const Sale({
    required this.id,
    required this.invoiceNo,
    this.customerId,
    this.customerName = 'Walk-in Customer',
    required this.subtotal,
    this.discount = 0,
    required this.total,
    required this.amountPaid,
    this.change = 0,
    this.balanceDue = 0,
    this.paymentStatus = PaymentStatus.paid,
    this.paymentMethod = SalePaymentMethod.cash,
    this.notes,
    this.voided = false,
    this.till = Till.general,
    this.linkedSaleId,
    this.createdBy,
    required this.createdAt,
    this.items = const [],
  });

  factory Sale.fromRow(
    Map<String, Object?> row, {
    List<SaleItem> items = const [],
  }) {
    return Sale(
      id: row['id'] as String,
      invoiceNo: row['invoice_no'] as String,
      customerId: row['customer_id'] as String?,
      customerName: (row['customer_name'] as String?) ?? 'Walk-in Customer',
      subtotal: (row['subtotal'] as num).toDouble(),
      discount: (row['discount'] as num?)?.toDouble() ?? 0,
      total: (row['total'] as num).toDouble(),
      amountPaid: (row['amount_paid'] as num).toDouble(),
      change: (row['change'] as num?)?.toDouble() ?? 0,
      balanceDue: (row['balance_due'] as num?)?.toDouble() ?? 0,
      paymentStatus: PaymentStatusValue.fromValue(row['payment_status'] as String?),
      paymentMethod: SalePaymentMethodValue.fromValue(row['payment_method'] as String?),
      notes: row['notes'] as String?,
      voided: (row['voided'] as int? ?? 0) == 1,
      till: TillValue.fromValue(row['till'] as String?),
      linkedSaleId: row['linked_sale_id'] as String?,
      createdBy: row['created_by'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      items: items,
    );
  }

  Map<String, Object?> toRow() => {
    'id': id,
    'invoice_no': invoiceNo,
    'customer_id': customerId,
    'customer_name': customerName,
    'subtotal': subtotal,
    'discount': discount,
    'total': total,
    'amount_paid': amountPaid,
    'change': change,
    'balance_due': balanceDue,
    'payment_status': paymentStatus.value,
    'payment_method': paymentMethod.value,
    'notes': notes,
    'voided': voided ? 1 : 0,
    'till': till.value,
    'linked_sale_id': linkedSaleId,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
  };
}
