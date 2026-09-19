enum DebtStatus { open, partial, settled }

extension DebtStatusValue on DebtStatus {
  String get value => switch (this) {
    DebtStatus.open => 'open',
    DebtStatus.partial => 'partial',
    DebtStatus.settled => 'settled',
  };

  static DebtStatus fromValue(String? v) => switch (v) {
    'partial' => DebtStatus.partial,
    'settled' => DebtStatus.settled,
    _ => DebtStatus.open,
  };
}

enum PaymentMethod { cash, mobile, bank, other }

extension PaymentMethodValue on PaymentMethod {
  String get value => switch (this) {
    PaymentMethod.cash => 'cash',
    PaymentMethod.mobile => 'mobile',
    PaymentMethod.bank => 'bank',
    PaymentMethod.other => 'other',
  };

  static PaymentMethod fromValue(String? v) => switch (v) {
    'mobile' => PaymentMethod.mobile,
    'bank' => PaymentMethod.bank,
    'other' => PaymentMethod.other,
    _ => PaymentMethod.cash,
  };
}

class Debt {
  final String id;
  final String customerId;
  final String? saleId;
  final double originalAmount;
  final double amountPaid;
  final double balance;
  final DebtStatus status;
  final DateTime? dueDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Debt({
    required this.id,
    required this.customerId,
    this.saleId,
    required this.originalAmount,
    this.amountPaid = 0,
    required this.balance,
    this.status = DebtStatus.open,
    this.dueDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Debt.fromRow(Map<String, Object?> row) {
    return Debt(
      id: row['id'] as String,
      customerId: row['customer_id'] as String,
      saleId: row['sale_id'] as String?,
      originalAmount: (row['original_amount'] as num).toDouble(),
      amountPaid: (row['amount_paid'] as num?)?.toDouble() ?? 0,
      balance: (row['balance'] as num).toDouble(),
      status: DebtStatusValue.fromValue(row['status'] as String?),
      dueDate: row['due_date'] == null
          ? null
          : DateTime.parse(row['due_date'] as String),
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, Object?> toRow() => {
    'id': id,
    'customer_id': customerId,
    'sale_id': saleId,
    'original_amount': originalAmount,
    'amount_paid': amountPaid,
    'balance': balance,
    'status': status.value,
    'due_date': dueDate?.toIso8601String(),
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

class DebtPayment {
  final String id;
  final String debtId;
  final double amount;
  final PaymentMethod method;
  final String? note;
  final DateTime paidAt;

  const DebtPayment({
    required this.id,
    required this.debtId,
    required this.amount,
    this.method = PaymentMethod.cash,
    this.note,
    required this.paidAt,
  });

  factory DebtPayment.fromRow(Map<String, Object?> row) {
    return DebtPayment(
      id: row['id'] as String,
      debtId: row['debt_id'] as String,
      amount: (row['amount'] as num).toDouble(),
      method: PaymentMethodValue.fromValue(row['method'] as String?),
      note: row['note'] as String?,
      paidAt: DateTime.parse(row['paid_at'] as String),
    );
  }

  Map<String, Object?> toRow() => {
    'id': id,
    'debt_id': debtId,
    'amount': amount,
    'method': method.value,
    'note': note,
    'paid_at': paidAt.toIso8601String(),
  };
}
