import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';
import 'package:amar_dokan/features/accounting/data/models/transaction_model.dart';
import 'package:amar_dokan/features/report/data/models/report_summary.dart';
import 'package:amar_dokan/features/report/presentation/widgets/kpi_card.dart';
import 'package:amar_dokan/features/report/presentation/widgets/simple_bar_chart.dart';

/// ProfitTab - financial summary and cash flow analysis.
///
/// Shows profit KPIs, cash flow (in vs out), the daily profit trend, and
/// expense breakdown by category.
class ProfitTab extends StatelessWidget {
  final ReportSummary summary;

  const ProfitTab({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      symbol: '৳',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    final isProfitable = summary.totalProfit > 0;
    final profitColor = isProfitable ? AppColors.success : AppColors.error;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // Headline profit card.
        Card(
          color: profitColor.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isProfitable
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: profitColor,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Total Profit',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currency.format(summary.totalProfit),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: profitColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Profit margin: ${summary.profitMargin.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Cash flow row.
        Row(
          children: [
            Expanded(
              child: KpiCard(
                title: 'Cash In',
                value: currency.format(summary.totalCashIn),
                subtitle: 'Revenue + income',
                icon: Icons.south_west,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                title: 'Cash Out',
                value: currency.format(summary.totalCashOut),
                subtitle: 'Purchases + expenses',
                icon: Icons.north_east,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Purchases row.
        Row(
          children: [
            Expanded(
              child: KpiCard(
                title: 'Purchases',
                value: currency.format(summary.totalPurchaseAmount),
                subtitle: '${summary.totalPurchases} orders',
                icon: Icons.shopping_bag,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                title: 'Payables',
                value: currency.format(summary.outstandingPayables),
                subtitle: 'Owed to suppliers',
                icon: Icons.account_balance,
                color: AppColors.error,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        const _SectionTitle('Daily Profit Trend'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: SimpleBarChart(
              dataPoints: [
                for (final p in summary.dailyProfitTrend)
                  ChartPoint(
                    label: p.label,
                    value: p.value,
                    tooltipValue:
                        '${p.fullLabel}: ${currency.format(p.value)}',
                  ),
              ],
              barColor: AppColors.success,
              height: 200,
            ),
          ),
        ),

        const SizedBox(height: 24),
        const _SectionTitle('Expenses by Category'),
        const SizedBox(height: 12),
        if (summary.expensesByCategory.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No expense transactions in this period.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          )
        else
          _ExpenseBreakdown(
            expenses: summary.expensesByCategory,
            total: summary.otherExpenses,
            formatter: currency,
          ),

        const SizedBox(height: 24),
        const _SectionTitle('Receivables vs Payables'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _NetRow(
                  label: 'Receivables',
                  sublabel: 'Customers owe you',
                  value: summary.outstandingReceivables,
                  formatter: currency,
                  color: AppColors.success,
                  icon: Icons.arrow_downward,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                _NetRow(
                  label: 'Payables',
                  sublabel: 'You owe suppliers',
                  value: summary.outstandingPayables,
                  formatter: currency,
                  color: AppColors.error,
                  icon: Icons.arrow_upward,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                _NetRow(
                  label: 'Net Position',
                  sublabel: 'Receivables − Payables',
                  value: summary.outstandingReceivables -
                      summary.outstandingPayables,
                  formatter: currency,
                  color: AppColors.primary,
                  icon: Icons.balance,
                  bold: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ExpenseBreakdown extends StatelessWidget {
  final Map<TransactionCategory, double> expenses;
  final double total;
  final NumberFormat formatter;

  const _ExpenseBreakdown({
    required this.expenses,
    required this.total,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    // Sort by amount descending.
    final entries = expenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _ExpenseRow(
              label: entries[i].key.label,
              amount: entries[i].value,
              percent: total == 0 ? 0 : entries[i].value / total,
              formatter: formatter,
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final String label;
  final double amount;
  final double percent;
  final NumberFormat formatter;

  const _ExpenseRow({
    required this.label,
    required this.amount,
    required this.percent,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                formatter.format(amount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final double value;
  final NumberFormat formatter;
  final Color color;
  final IconData icon;
  final bool bold;

  const _NetRow({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.formatter,
    required this.color,
    required this.icon,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: bold ? 15 : 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                sublabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          formatter.format(value),
          style: TextStyle(
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}