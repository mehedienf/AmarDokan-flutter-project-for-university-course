import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/features/inventory/data/models/product_model.dart';
import 'package:amar_dokan/features/inventory/providers/inventory_provider.dart';
import 'package:amar_dokan/features/inventory/presentation/widgets/product_form.dart';
import 'package:amar_dokan/core/constants/app_colors.dart';

/// Edit Product Screen
/// Existing product update করার জন্য
class EditProductScreen extends StatelessWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  Future<void> _handleSubmit(
    BuildContext context,
    ProductModel updatedProduct,
  ) async {
    final success = await context
        .read<InventoryProvider>()
        .updateProduct(updatedProduct);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Product updated successfully!' : 'Failed to update product',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );

    if (success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ProductForm(
        initialProduct: product,
        onSubmit: (updatedProduct) => _handleSubmit(context, updatedProduct),
      ),
    );
  }
}