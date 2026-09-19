import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../debts/models/debt.dart';
import '../../debts/providers/debts_provider.dart';
import '../models/customer.dart';

class CustomersFilterNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setSearch(String value) => state = value;
}

final customersSearchProvider =
    NotifierProvider<CustomersFilterNotifier, String>(
      CustomersFilterNotifier.new,
    );

final customersListProvider = FutureProvider.autoDispose<List<Customer>>((
  ref,
) async {
  final search = ref.watch(customersSearchProvider);
  return CustomerRepository.instance.getAll(search: search);
});

/// Live-computed total debt per customer, batched for the list screen.
final customerDebtTotalsProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
      final customers = await ref.watch(customersListProvider.future);
      return CustomerRepository.instance.getTotalDebts(
        customers.map((c) => c.id).toList(),
      );
    });

final customerByIdProvider = FutureProvider.autoDispose
    .family<Customer?, String>((ref, id) {
      return CustomerRepository.instance.getById(id);
    });

final customerTotalDebtProvider = FutureProvider.autoDispose
    .family<double, String>((ref, customerId) {
      return CustomerRepository.instance.getTotalDebt(customerId);
    });

final customerDebtsProvider = FutureProvider.autoDispose
    .family<List<Debt>, String>((ref, customerId) {
      return CustomerRepository.instance.getDebtsForCustomer(customerId);
    });

final debtPaymentsProvider = FutureProvider.autoDispose
    .family<List<DebtPayment>, String>((ref, debtId) {
      return CustomerRepository.instance.getPaymentsForDebt(debtId);
    });

class CustomersController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  void _invalidateListsFor(Ref ref, [String? customerId]) {
    ref.invalidate(customersListProvider);
    ref.invalidate(customerDebtTotalsProvider);
    ref.invalidate(debtsOverviewProvider);
    if (customerId != null) {
      ref.invalidate(customerByIdProvider(customerId));
      ref.invalidate(customerTotalDebtProvider(customerId));
      ref.invalidate(customerDebtsProvider(customerId));
    }
  }

  Future<bool> createCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await CustomerRepository.instance.create(
        name: name,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
      );
      _invalidateListsFor(ref);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateCustomer({
    required String id,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await CustomerRepository.instance.update(
        id: id,
        name: name,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
      );
      _invalidateListsFor(ref, id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> setActive(String id, bool active) async {
    try {
      await CustomerRepository.instance.setActive(id, active);
      _invalidateListsFor(ref, id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> recordDebtPayment({
    required String debtId,
    required String customerId,
    required double amount,
    PaymentMethod method = PaymentMethod.cash,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    try {
      await CustomerRepository.instance.recordDebtPayment(
        debtId: debtId,
        amount: amount,
        method: method,
        note: note,
      );
      _invalidateListsFor(ref, customerId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final customersControllerProvider =
    NotifierProvider<CustomersController, AsyncValue<void>>(
      CustomersController.new,
    );
