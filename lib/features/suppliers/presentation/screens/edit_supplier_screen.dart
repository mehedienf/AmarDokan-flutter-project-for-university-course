import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/features/suppliers/data/models/supplier_model.dart';
import 'package:amar_dokan/features/suppliers/providers/supplier_provider.dart';
import 'package:amar_dokan/features/suppliers/presentation/widgets/supplier_form.dart';
import 'package:amar_dokan/core/constants/app_colors.dart';

/// Edit Supplier Screen - Wraps SupplierForm for editing an existing supplier
class EditSupplierScreen extends StatelessWidget {
  final SupplierModel supplier;

  const EditSupplierScreen({super.key, required this.supplier});

  Future<void> _handleSubmit(
    BuildContext context,
    SupplierModel updatedSupplier,
  ) async {
    bool success = false;
    try {
      await context.read<SupplierProvider>().updateSupplier(updatedSupplier);
      success = true;
    } catch (_) {
      success = false;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Supplier updated successfully!' : 'Failed to update supplier',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      if (success) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Supplier'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SupplierForm(
          initialSupplier: supplier,
          onCancel: () => Navigator.of(context).pop(),
          onSubmit: (updated) => _handleSubmit(context, updated),
        ),
      ),
    );
  }
}
