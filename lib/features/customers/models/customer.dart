class Customer {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;

  /// Running lifetime total, incremented on each completed sale.
  /// This is the ONLY running total stored on Customer — total debt is
  /// deliberately never cached here (see debts.dart / CustomerRepository).
  final double totalPurchases;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.totalPurchases = 0,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Customer copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    double? totalPurchases,
    bool? active,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Customer.fromRow(Map<String, Object?> row) {
    return Customer(
      id: row['id'] as String,
      name: row['name'] as String,
      phone: row['phone'] as String?,
      email: row['email'] as String?,
      address: row['address'] as String?,
      notes: row['notes'] as String?,
      totalPurchases: (row['total_purchases'] as num?)?.toDouble() ?? 0,
      active: (row['active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, Object?> toRow() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'notes': notes,
    'total_purchases': totalPurchases,
    'active': active ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
