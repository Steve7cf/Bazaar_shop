import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../widgets/till_tabs.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  TillFilter _till = TillFilter.all;

  // Placeholder series until the reports/insights repository is wired up.
  static const _mockRevenue = [420.0, 610.0, 380.0, 720.0, 655.0, 890.0, 760.0];
  static const _mockDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const _mockStats = [
    (
      icon: Icons.today_rounded,
      value: 'Tsh 760,000',
      label: "Today's sales",
      delta: '12.4%',
      deltaPositive: true,
    ),
    (
      icon: Icons.calendar_view_week_rounded,
      value: 'Tsh 4.4M',
      label: 'This week',
      delta: '3.1%',
      deltaPositive: true,
    ),
    (
      icon: Icons.calendar_month_rounded,
      value: 'Tsh 18.2M',
      label: 'This month',
      delta: '2.8%',
      deltaPositive: false,
    ),
    (
      icon: Icons.request_quote_rounded,
      value: 'Tsh 1.1M',
      label: 'Outstanding debt',
      delta: null,
      deltaPositive: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TillTabs(value: _till, onChanged: (f) => setState(() => _till = f)),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final s in _mockStats)
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        icon: s.icon,
                        value: s.value,
                        label: s.label,
                        delta: s.delta,
                        deltaPositive: s.deltaPositive,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeader(title: 'Revenue — last 7 days'),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 200,
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(
              color: palette.bgSecondary,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: palette.border),
            ),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= _mockDays.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _mockDays[i],
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.textTertiary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < _mockRevenue.length; i++)
                        FlSpot(i.toDouble(), _mockRevenue[i]),
                    ],
                    isCurved: true,
                    color: palette.accent,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: palette.accent.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeader(title: 'Low stock'),
          const SizedBox(height: AppSpacing.sm),
          const _LowStockTile(name: 'Sukari 1kg', qty: '3.0 kg left', tone: BadgeTone.danger),
          const _LowStockTile(name: 'Mafuta 2L', qty: '4.5 L left', tone: BadgeTone.warning),
          const _LowStockTile(name: 'Unga wa Ngano', qty: '1.0 kg left', tone: BadgeTone.danger),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeader(title: 'Top products this month'),
          const SizedBox(height: AppSpacing.sm),
          const _TopProductTile(rank: 1, name: 'Sukari 1kg', revenue: 'Tsh 1,240,000'),
          const _TopProductTile(rank: 2, name: 'Coca-Cola 500ml', revenue: 'Tsh 980,000'),
          const _TopProductTile(rank: 3, name: 'Mafuta 2L', revenue: 'Tsh 760,000'),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeader(title: 'Recent sales'),
          const SizedBox(height: AppSpacing.sm),
          const _RecentSaleTile(invoice: 'BZ-260917-K3F9A', amount: 'Tsh 24,500', status: 'paid'),
          const _RecentSaleTile(invoice: 'BZ-260917-P8Q2Z', amount: 'Tsh 12,000', status: 'partial'),
          const _RecentSaleTile(invoice: 'BZ-260916-M1X7T', amount: 'Tsh 48,000', status: 'debt'),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _LowStockTile extends StatelessWidget {
  final String name;
  final String qty;
  final BadgeTone tone;

  const _LowStockTile({
    required this.name,
    required this.qty,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: palette.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_rounded, size: 18, color: palette.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.textPrimary),
            ),
          ),
          Text(
            qty,
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusBadge(
            label: tone == BadgeTone.danger ? 'Low' : 'Watch',
            tone: tone,
          ),
        ],
      ),
    );
  }
}

class _TopProductTile extends StatelessWidget {
  final int rank;
  final String name;
  final String revenue;

  const _TopProductTile({
    required this.rank,
    required this.name,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: palette.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                color: palette.accent,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.textPrimary),
            ),
          ),
          Text(
            revenue,
            style: TextStyle(fontWeight: FontWeight.w600, color: palette.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _RecentSaleTile extends StatelessWidget {
  final String invoice;
  final String amount;
  final String status;

  const _RecentSaleTile({
    required this.invoice,
    required this.amount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tone = switch (status) {
      'paid' => BadgeTone.success,
      'partial' => BadgeTone.warning,
      _ => BadgeTone.danger,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: palette.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              invoice,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: palette.textPrimary,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(fontWeight: FontWeight.w600, color: palette.textPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusBadge(label: status, tone: tone),
        ],
      ),
    );
  }
}
