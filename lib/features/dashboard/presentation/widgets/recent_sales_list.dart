import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';
import 'package:amar_dokan/features/sales/data/models/sale_model.dart';

/// RecentSalesList - vertical list of the most recent sales.
///
/// Each row shows invoice number, customer (or "Walk-in"), total, and a
/// relative time. Empty state when there are no sales yet.
class RecentSalesList extends StatelessWidget {
  final List<SaleModel> sales;

  const RecentSalesList({super.key, required this.sales});

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 36,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No sales yet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Recent sales will appear here.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < sales.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            _SaleRow(sale: sales[i]),
          ],
        ],
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  final SaleModel sale;

  const _SaleRow({required this.sale});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      symbol: '৳',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    final date = sale.saleDate ?? sale.createdAt;
    final customerLabel = sale.customerName?.trim();
    final customerName = (customerLabel == null || customerLabel.isEmpty)
        ? 'Walk-in'
        : customerLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Payment-method indicator chip.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _methodColor(sale.paymentMethod).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _methodIcon(sale.paymentMethod),
              color: _methodColor(sale.paymentMethod),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Center: invoice + customer.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.invoiceNumber.isEmpty ? '#${sale.id.substring(0, 6)}' : sale.invoiceNumber,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Right: total + relative time.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency.format(sale.total),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _relativeTime(date),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _methodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.payments_outlined;
      case 'card':
        return Icons.credit_card;
      case 'mobile':
      case 'mobile_banking':
      case 'bkash':
      case 'nagad':
        return Icons.phone_android;
      case 'bank':
      case 'bank_transfer':
        return Icons.account_balance;
      case 'credit':
        return Icons.receipt_long_outlined;
      default:
        return Icons.payments_outlined;
    }
  }

  static Color _methodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return AppColors.success;
      case 'card':
        return AppColors.info;
      case 'mobile':
      case 'mobile_banking':
      case 'bkash':
      case 'nagad':
        return AppColors.secondary;
      case 'bank':
      case 'bank_transfer':
        return AppColors.primary;
      case 'credit':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  static String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(dt);
  }
}