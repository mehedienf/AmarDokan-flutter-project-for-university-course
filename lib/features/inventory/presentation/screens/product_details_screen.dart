import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/features/inventory/data/models/product_model.dart';
import 'package:amar_dokan/features/inventory/providers/inventory_provider.dart';
import 'package:amar_dokan/features/inventory/presentation/screens/edit_product_screen.dart';
import 'package:amar_dokan/core/constants/app_colors.dart';

/// Product Details Screen
/// Product এর সব info একসাথে দেখায় + Edit/Delete actions
class ProductDetailsScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  // Delete confirmation
  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success =
          await context.read<InventoryProvider>().deleteProduct(product.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(success ? 'Product deleted!' : 'Failed to delete'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        if (success) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<void> _navigateToEdit(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProductScreen(product: product),
      ),
    );

    // Edit থেকে updated product back আসলে pop করি
    if (result == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => _navigateToEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(),

            const SizedBox(height: 16),

            // Stock Status
            _buildStockStatusCard(),

            const SizedBox(height: 16),

            // Pricing Info
            _buildPricingCard(),

            const SizedBox(height: 16),

            // Details
            _buildDetailsCard(),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToEdit(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Product'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: product.isOutOfStock
                  ? AppColors.error
                  : product.isLowStock
                      ? AppColors.warning
                      : AppColors.primary,
              child: Text(
                product.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${product.sku}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.category.displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockStatusCard() {
    final stockColor = product.isOutOfStock
        ? AppColors.error
        : product.isLowStock
            ? AppColors.warning
            : AppColors.success;
    final stockLabel = product.isOutOfStock
        ? 'Out of Stock'
        : product.isLowStock
            ? 'Low Stock'
            : 'In Stock';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Stock Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox(
                  label: 'Current Stock',
                  value: '${product.stock}',
                  color: stockColor,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                ),
                _buildStatBox(
                  label: 'Threshold',
                  value: '${product.lowStockThreshold}',
                  color: AppColors.textSecondary,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                ),
                _buildStatBox(
                  label: 'Status',
                  value: stockLabel,
                  color: stockColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: stockColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: stockColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product.isOutOfStock
                          ? 'This product is out of stock. Restock immediately.'
                          : product.isLowStock
                              ? 'Stock is below threshold (${product.lowStockThreshold}). Consider restocking.'
                              : 'Stock level is healthy.',
                      style: TextStyle(color: stockColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.attach_money, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Pricing & Profit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPriceRow('Purchase Price', '৳${product.purchasePrice.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildPriceRow(
              'Selling Price',
              '৳${product.sellingPrice.toStringAsFixed(2)}',
              highlight: true,
            ),
            const SizedBox(height: 8),
            Divider(color: AppColors.textSecondary.withValues(alpha: 0.2)),
            const SizedBox(height: 8),
            _buildPriceRow(
              'Profit per Unit',
              '৳${product.profitPerUnit.toStringAsFixed(2)}',
              color: AppColors.success,
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              'Profit Margin',
              '${product.profitMarginPercentage.toStringAsFixed(1)}%',
              color: AppColors.success,
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              'Total Stock Value',
              '৳${product.totalStockValue.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              'Potential Profit',
              '৳${product.totalPotentialProfit.toStringAsFixed(2)}',
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool highlight = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 16 : 14,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            color: color ?? (highlight ? AppColors.primary : Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              (product.description != null && product.description!.isNotEmpty)
                  ? product.description!
                  : 'No description provided.',
              style: TextStyle(
                color: (product.description != null &&
                        product.description!.isNotEmpty)
                    ? Colors.black87
                    : AppColors.textSecondary,
                fontStyle: (product.description != null &&
                        product.description!.isNotEmpty)
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.calendar_today,
              'Created',
              _formatDate(product.createdAt),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.update,
              'Last Updated',
              _formatDate(product.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}