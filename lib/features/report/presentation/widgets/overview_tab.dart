import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';
import 'package:amar_dokan/features/report/data/models/report_summary.dart';
import 'package:amar_dokan/features/report/presentation/widgets/kpi_card.dart';
import 'package:amar_dokan/features/report/presentation/widgets/simple_bar_chart.dart';

/// OverviewTab - top-level summary tab.
///
/// Shows four headline KPI cards (Revenue, Profit, Expenses, Net Cash Flow)
/// followed by a sales trend chart and a top-products list.
class OverviewTab extends StatelessWidget {
  final ReportSummary summary;

  const OverviewTab({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      symbol: '৳',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    final revenueKpi = KpiCard(
      title: 'Revenue',
      value: currency.format(summary.totalRevenue),
      subtitle: '${summary.completedSales} completed sales',
      icon: Icons.attach_money,
      color: AppColors.primary,
    );

    final profitKpi = KpiCard(
      title: 'Profit',
      value: currency.format(summary.totalProfit),
      subtitle:
          'Margin ${summary.profitMargin.toStringAsFixed(1)}%',
      icon: Icons.trending_up,
      color: AppColors.success,
    );

    final expensesKpi = KpiCard(
      title: 'Expenses',
      value: currency.format(summary.otherExpenses),
      subtitle: '${summary.expenseTransactionCount} transactions',
      icon: Icons.trending_down,
      color: AppColors.error,
    );

    final cashFlowKpi = KpiCard(
      title: 'Net Cash Flow',
      value: currency.format(summary.netCashFlow),
      subtitle: summary.netCashFlow >= 0 ? 'Positive' : 'Negative',
      icon: summary.netCashFlow >= 0
          ? Icons.south_west
          : Icons.north_east,
      color: summary.netCashFlow >= 0
          ? AppColors.success
          : AppColors.error,
    );

    final inventoryKpi = KpiCard(
      title: 'Inventory Value',
      value: currency.format(summary.totalInventoryValue),
      subtitle: '${summary.totalProducts} products',
      icon: Icons.inventory_2,
      color: AppColors.secondary,
    );

    final receivablesKpi = KpiCard(
      title: 'Receivables',
      value: currency.format(summary.outstandingReceivables),
      subtitle: 'Unpaid from customers',
      icon: Icons.account_balance_wallet,
      color: AppColors.warning,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // Headline row — 2 cards.
        Row(
          children: [
            Expanded(child: revenueKpi),
            const SizedBox(width: 12),
            Expanded(child: profitKpi),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: cashFlowKpi),
            const SizedBox(width: 12),
            Expanded(child: expensesKpi),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: inventoryKpi),
            const SizedBox(width: 12),
            Expanded(child: receivablesKpi),
          ],
        ),

        const SizedBox(height: 24),
        _SectionTitle('Sales Trend', 'Daily revenue for ${summary.period.label}'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: SimpleBarChart(
              dataPoints: [
                for (final p in summary.dailySalesTrend)
                  ChartPoint(
                    label: p.label,
                    value: p.value,
                    tooltipValue:
                        '${p.fullLabel}: ${currency.format(p.value)}',
                  ),
              ],
              barColor: AppColors.primary,
              height: 200,
            ),
          ),
        ),

        const SizedBox(height: 24),
        _SectionTitle('Top Products', 'Best sellers by revenue'),
        const SizedBox(height: 12),
        if (summary.topProducts.isEmpty)
          const _EmptyHint('No sales recorded in this period.')
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < summary.topProducts.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _RankingRow(
                    rank: i + 1,
                    name: summary.topProducts[i].name,
                    subtitle: summary.topProducts[i].subtitle,
                    value: currency.format(summary.topProducts[i].value),
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 24),
        _SectionTitle('Top Customers', 'Highest revenue customers'),
        const SizedBox(height: 12),
        if (summary.topCustomers.isEmpty)
          const _EmptyHint('No customer data in this period.')
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < summary.topCustomers.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _RankingRow(
                    rank: i + 1,
                    name: summary.topCustomers[i].name,
                    subtitle: summary.topCustomers[i].subtitle,
                    value: currency.format(summary.topCustomers[i].value),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionTitle(this.title, [this.subtitle]);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _RankingRow extends StatelessWidget {
  final int rank;
  final String name;
  final String? subtitle;
  final String value;

  const _RankingRow({
    required this.rank,
    required this.name,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? AppColors.secondary.withValues(alpha: 0.15)
                  : AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? AppColors.secondary : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}