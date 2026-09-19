import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../customers/models/customer.dart';
import '../models/debt.dart';

/// One customer with all of their (non-settled, most-recent-first) debts
/// nested underneath, per spec Section 7: "a customer with three separate
/// debts should appear once, with all three nested underneath and a
/// summed balance."
class CustomerDebtGroup {
  final Customer customer;
  final List<Debt> debts;

  const CustomerDebtGroup({required this.customer, required this.debts});

  double get totalBalance =>
      debts.fold(0.0, (sum, d) => sum + d.balance);
}

class DebtsOverview {
  final List<CustomerDebtGroup> groups;
  final double totalOutstanding;

  const DebtsOverview({required this.groups, required this.totalOutstanding});
}

final debtsSearchProvider = NotifierProvider<DebtsSearchNotifier, String>(
  DebtsSearchNotifier.new,
);

class DebtsSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setSearch(String value) => state = value;
}

/// Customers with at least one non-settled debt, sorted by highest
/// outstanding balance first (spec Section 7). Each group's debts are
/// pre-sorted newest-first within the group.
final debtsOverviewProvider = FutureProvider.autoDispose<DebtsOverview>((
  ref,
) async {
  final search = ref.watch(debtsSearchProvider);
  final repo = CustomerRepository.instance;

  // All customers (active + inactive — a customer who owes money shouldn't
  // silently disappear from the debts view just because they were
  // deactivated) with a search filter applied the same way the Customers
  // screen does.
  final customers = await repo.getAll(activeOnly: false, search: search);
  if (customers.isEmpty) {
    return const DebtsOverview(groups: [], totalOutstanding: 0);
  }

  final debtsByCustomer = await repo.getOpenDebtsForCustomers(
    customers.map((c) => c.id).toList(),
  );

  final groups = <CustomerDebtGroup>[];
  var totalOutstanding = 0.0;

  for (final customer in customers) {
    final open = debtsByCustomer[customer.id];
    if (open == null || open.isEmpty) continue;

    final group = CustomerDebtGroup(customer: customer, debts: open);
    groups.add(group);
    totalOutstanding += group.totalBalance;
  }

  groups.sort((a, b) => b.totalBalance.compareTo(a.totalBalance));

  return DebtsOverview(groups: groups, totalOutstanding: totalOutstanding);
});
