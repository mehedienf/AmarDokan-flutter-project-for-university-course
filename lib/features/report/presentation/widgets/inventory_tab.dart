import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';
import 'package:amar_dokan/features/report/data/models/report_summary.dart';
import 'package:amar_dokan/features/report/presentation/widgets/kpi_card.dart';

/// InventoryTab - inventory snapshot and category breakdown.
///
/// Note: inventory metrics are point-in-time (not range-filtered) since
/// stock-on-hand is a current-state quantity, not a period aggregate.
class InventoryTab extends StatelessWidget {
  final ReportSummary summary;

  const InventoryTab({super.key, required this.summary});

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
                title: 'Inventory Value',
                value: currency.format(summary.totalInventoryValue),
                subtitle: '${summary.totalProducts} products',
                icon: Icons.inventory_2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                title: 'Potential Profit',
                value: currency.format(summary.totalInventoryPotentialProfit),
                subtitle: 'If all sold',
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                title: 'Total Stock',
                value: summary.totalStockUnits.toString(),
                subtitle: 'Units on hand',
                icon: Icons.layers,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                title: 'Low Stock',
                value: summary.lowStockCount.toString(),
                subtitle: 'Need reorder',
                icon: Icons.warning_amber,
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
                title: 'Out of Stock',
                value: summary.outOfStockCount.toString(),
                subtitle: 'Restock needed',
                icon: Icons.error,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                title: 'Products',
                value: summary.totalProducts.toString(),
                subtitle: 'Total SKUs',
                icon: Icons.category,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        const _SectionTitle('Top Categories by Potential Profit'),
        const SizedBox(height: 12),
        if (summary.topCategoriesByProfit.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No products in inventory yet.',
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
                    i < summary.topCategoriesByProfit.length;
                    i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _CategoryRow(
                    rank: i + 1,
                    name: summary.topCategoriesByProfit[i].name,
                    value: summary.topCategoriesByProfit[i].value,
                    maxValue: summary.topCategoriesByProfit.first.value,
                    formatter: currency,
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 24),
        const _SectionTitle('Stock Alerts'),
        const SizedBox(height: 12),
        _StockAlertCard(
          count: summary.lowStockCount,
          type: AlertType.lowStock,
        ),
        const SizedBox(height: 8),
        _StockAlertCard(
          count: summary.outOfStockCount,
          type: AlertType.outOfStock,
        ),
      ],
    );
  }
}

enum AlertType { lowStock, outOfStock }

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

class _CategoryRow extends StatelessWidget {
  final int rank;
  final String name;
  final double value;
  final double maxValue;
  final NumberFormat formatter;

  const _CategoryRow({
    required this.rank,
    required this.name,
    required this.value,
    required this.maxValue,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#$rank',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                formatter.format(value),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockAlertCard extends StatelessWidget {
  final int count;
  final AlertType type;

  const _StockAlertCard({required this.count, required this.type});

  Color get _color {
    switch (type) {
      case AlertType.lowStock:
        return AppColors.warning;
      case AlertType.outOfStock:
        return AppColors.error;
    }
  }

  IconData get _icon {
    switch (type) {
      case AlertType.lowStock:
        return Icons.warning_amber;
      case AlertType.outOfStock:
        return Icons.remove_circle;
    }
  }

  String get _title {
    switch (type) {
      case AlertType.lowStock:
        return 'Low Stock Items';
      case AlertType.outOfStock:
        return 'Out of Stock Items';
    }
  }

  String get _subtitle {
    if (count == 0) {
      switch (type) {
        case AlertType.lowStock:
          return 'All products are well-stocked.';
        case AlertType.outOfStock:
          return 'No out-of-stock products. Great!';
      }
    }
    return count == 1 ? '1 product needs attention' : '$count products need attention';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(_icon, color: _color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}