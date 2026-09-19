import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/customers_provider.dart';
import '../widgets/customer_list_tile.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final customersAsync = ref.watch(customersListProvider);
    final debtTotalsAsync = ref.watch(customerDebtTotalsProvider);
    final search = ref.watch(customersSearchProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/customers/new'),
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(customersSearchProvider.notifier)
                              .setSearch('');
                        },
                      ),
              ),
              onChanged: (v) =>
                  ref.read(customersSearchProvider.notifier).setSearch(v),
            ),
          ),
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 48,
                          color: palette.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          search.isEmpty
                              ? 'No customers yet — tap + to add one'
                              : 'No customers match your search',
                          style: TextStyle(color: palette.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                final debtTotals = debtTotalsAsync.value;
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    88,
                  ),
                  itemCount: customers.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final customer = customers[i];
                    return CustomerListTile(
                      customer: customer,
                      totalDebt: debtTotals == null
                          ? null
                          : (debtTotals[customer.id] ?? 0),
                      onTap: () =>
                          context.push('/home/customers/${customer.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Could not load customers',
                  style: TextStyle(color: palette.danger),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
