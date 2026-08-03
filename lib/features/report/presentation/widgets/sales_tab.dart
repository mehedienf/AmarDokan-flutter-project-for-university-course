import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';
import 'package:amar_dokan/features/report/data/models/report_summary.dart';
import 'package:amar_dokan/features/report/presentation/widgets/kpi_card.dart';
import 'package:amar_dokan/features/report/presentation/widgets/simple_bar_chart.dart';

/// SalesTab - detailed sales analytics.
///
/// Shows sales KPIs (revenue, avg sale, items sold, transactions), the
/// daily profit trend, and payment-method breakdown.
class SalesTab extends StatelessWidget {
  final ReportSummary summary;

  const SalesTab({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      symbol: '৳',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: KpiCard(
                title: 'Revenue',
                value: currency.format(summary.totalRevenue),
                subtitle: '${summary.completedSales} sales',
                icon: Icons.point_of_sale,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                title: 'Avg Sale',
                value: currency.format(summary.averageSaleValue),
                subtitle: 'Per transaction',
                icon: Icons.analytics,
                color: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                title: 'Items Sold',
                value: summary.totalItemsSold.toString(),
                subtitle: 'Units moved',
                icon: Icons.shopping_cart,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                title: 'Discounts',
                value: currency.format(summary.totalDiscount),
                subtitle: 'Total given',
                icon: Icons.local_offer,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                title: 'Tax',
                value: currency.format(summary.totalTax),
                subtitle: 'Collected',
                icon: Icons.receipt_long,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                title: 'Cancelled',
                value: summary.cancelledSales.toString(),
                subtitle: 'Sales voided',
                icon: Icons.cancel,
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
        const _SectionTitle('Payment Methods'),
        const SizedBox(height: 12),
        if (summary.paymentMethodBreakdown.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No completed sales in this period.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0;
                    i < summary.paymentMethodBreakdown.length;
                    i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _PaymentRow(
                    method: summary.paymentMethodBreakdown[i].name,
                    count: summary.paymentMethodBreakdown[i].value.toInt(),
                    subtitle: summary.paymentMethodBreakdown[i].subtitle,
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 24),
        const _SectionTitle('Top Products'),
        const SizedBox(height: 12),
        if (summary.topProducts.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No product sales yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < summary.topProducts.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(summary.topProducts[i].name),
                    subtitle: Text(summary.topProducts[i].subtitle ?? ''),
                    trailing: Text(
                      currency.format(summary.topProducts[i].value),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
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

class _PaymentRow extends StatelessWidget {
  final String method;
  final int count;
  final String? subtitle;

  const _PaymentRow({
    required this.method,
    required this.count,
    this.subtitle,
  });

  IconData get _icon {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.payments;
      case 'card':
        return Icons.credit_card;
      case 'mobile banking':
        return Icons.phone_android;
      case 'bank transfer':
        return Icons.account_balance;
      default:
        return Icons.attach_money;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}