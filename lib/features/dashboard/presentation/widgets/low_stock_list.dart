import 'package:flutter/material.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';
import 'package:amar_dokan/features/inventory/data/models/product_category.dart';
import 'package:amar_dokan/features/inventory/data/models/product_model.dart';

/// LowStockList - vertical list of low/out-of-stock products.
///
/// Caller passes the already-filtered + sorted list. Empty state when
/// everything is healthy.
class LowStockList extends StatelessWidget {
  final List<ProductModel> products;

  const LowStockList({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 36,
                  color: AppColors.success.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 8),
                const Text(
                  'All stock levels healthy',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'No products need attention right now.',
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
          for (var i = 0; i < products.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            _ProductRow(product: products[i]),
          ],
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final ProductModel product;

  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final isOut = product.isOutOfStock;
    final statusColor = isOut ? AppColors.error : AppColors.warning;
    final statusLabel = isOut ? 'Out of Stock' : 'Low Stock';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Category badge.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _categoryIcon(product.category),
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Center: name + category.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.category.displayName,
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
          // Right: stock + status badge.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.stock} left',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _categoryIcon(ProductCategory category) {
    switch (category) {
      case ProductCategory.food:
        return Icons.restaurant;
      case ProductCategory.beverages:
        return Icons.local_drink;
      case ProductCategory.grocery:
        return Icons.shopping_basket;
      case ProductCategory.medicine:
        return Icons.medical_services;
      case ProductCategory.cosmetics:
        return Icons.soap;
      case ProductCategory.stationery:
        return Icons.edit_note;
      case ProductCategory.electronics:
        return Icons.devices;
      case ProductCategory.clothing:
        return Icons.checkroom;
      case ProductCategory.hardware:
        return Icons.handyman;
      case ProductCategory.other:
        return Icons.category;
    }
  }
}