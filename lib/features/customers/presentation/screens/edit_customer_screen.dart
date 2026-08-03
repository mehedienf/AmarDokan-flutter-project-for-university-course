import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/features/customers/data/models/customer_model.dart';
import 'package:amar_dokan/features/customers/providers/customer_provider.dart';
import 'package:amar_dokan/features/customers/presentation/widgets/customer_form.dart';
import 'package:amar_dokan/core/constants/app_colors.dart';

/// Edit Customer Screen
/// Existing customer update করার জন্য
class EditCustomerScreen extends StatelessWidget {
  final CustomerModel customer;

  const EditCustomerScreen({super.key, required this.customer});

  Future<void> _handleSubmit(
    BuildContext context,
    CustomerModel updatedCustomer,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    bool success = false;
    try {
      await context
          .read<CustomerProvider>()
          .updateCustomer(updatedCustomer);
      success = true;
    } catch (_) {
      success = false;
    }

    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Customer updated successfully!' : 'Failed to update customer',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );

    if (success) {
      navigator.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Customer'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: CustomerForm(
        initialCustomer: customer,
        onSubmit: (updatedCustomer) => _handleSubmit(context, updatedCustomer),
      ),
    );
  }
}
