import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/features/inventory/data/models/product_model.dart';
import 'package:amar_dokan/features/inventory/providers/inventory_provider.dart';
import 'package:amar_dokan/features/inventory/presentation/widgets/product_form.dart';
import 'package:amar_dokan/features/inventory/presentation/screens/product_details_screen.dart';
import 'package:amar_dokan/core/constants/app_colors.dart';

/// Inventory Screen - Products list with Firestore backend
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    // Firestore stream শুরু করি
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().startListening();
    });
  }

  // Snackbar helper
  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: color,
      ),
    );
  }

  // Delete confirmation dialog
  Future<void> _showDeleteDialog(
    BuildContext context,
    ProductModel product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.name}"?',
        ),
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

    if (confirmed == true && product.id.isNotEmpty && context.mounted) {
      final success =
          await context.read<InventoryProvider>().deleteProduct(product.id);
      if (context.mounted) {
        _showSnackBar(
          context,
          success
              ? 'Product deleted successfully!'
              : 'Failed to delete product',
          success ? AppColors.success : AppColors.error,
        );
      }
    }
  }

  // Add Product Dialog
  Future<void> _showAddProductForm(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ProductForm(
          onCancel: () => Navigator.of(ctx).pop(),
          onSubmit: (product) async {
            final success =
                await context.read<InventoryProvider>().addProduct(product);
            if (ctx.mounted) {
              Navigator.of(ctx).pop();
              if (context.mounted) {
                _showSnackBar(
                  context,
                  success ? 'Product added!' : 'Failed to add',
                  success ? AppColors.success : AppColors.error,
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _navigateToDetails(BuildContext context, ProductModel product) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          // Loading state
          if (provider.isLoading && provider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.errorMessage}',
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.startListening();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (provider.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No products yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to add your first product',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Product list
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.products.length,
            itemBuilder: (context, index) {
              final product = provider.products[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  onTap: () => _navigateToDetails(context, product),
                  leading: CircleAvatar(
                    backgroundColor: product.isLowStock
                        ? AppColors.warning
                        : product.isOutOfStock
                            ? AppColors.error
                            : AppColors.primary,
                    child: Text(
                      product.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(product.name),
                  subtitle: Text(
                    '৳${product.sellingPrice.toStringAsFixed(2)} • Stock: ${product.stock}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () => _showDeleteDialog(context, product),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductForm(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
