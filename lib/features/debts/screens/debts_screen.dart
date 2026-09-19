import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../providers/debts_provider.dart';
import '../widgets/customer_debt_card.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final overviewAsync = ref.watch(debtsOverviewProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm + 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                overviewAsync.when(
                  data: (overview) => _TotalOutstandingBanner(
                    total: overview.totalOutstanding,
                    customerCount: overview.groups.length,
                  ),
                  loading: () => const _TotalOutstandingBanner(
                    total: null,
                    customerCount: null,
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
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
                                  .read(debtsSearchProvider.notifier)
                                  .setSearch('');
                            },
                          ),
                  ),
                  onChanged: (v) {
                    setState(() {});
                    ref.read(debtsSearchProvider.notifier).setSearch(v);
                  },
                ),
              ],
            ),
          ),
          Divider(height: 1, color: palette.border),
          Expanded(
            child: overviewAsync.when(
              data: (overview) {
                if (overview.groups.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: palette.success.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle_outline_rounded,
                              size: 32,
                              color: palette.success,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No outstanding debts',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Debts created from unpaid sales will show up here, grouped by customer',
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(debtsOverviewProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xl,
                    ),
                    itemCount: overview.groups.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm + 2),
                    itemBuilder: (context, i) {
                      final group = overview.groups[i];
                      return CustomerDebtCard(
                        group: group,
                        onTap: () => context.push(
                          '/home/customers/${group.customer.id}',
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Text(
                  'Could not load debts',
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

class _TotalOutstandingBanner extends StatelessWidget {
  final double? total;
  final int? customerCount;

  const _TotalOutstandingBanner({required this.total, required this.customerCount});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.danger.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.request_quote_rounded,
              color: palette.danger,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == null ? '…' : formatTsh(total!),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: palette.danger,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customerCount == null
                      ? 'Total outstanding'
                      : 'Outstanding across $customerCount ${customerCount == 1 ? 'customer' : 'customers'}',
                  style: TextStyle(fontSize: 12.5, color: palette.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
