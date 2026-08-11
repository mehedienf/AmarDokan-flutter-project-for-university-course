import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/features/customers/data/models/customer_model.dart';
import 'package:amar_dokan/features/customers/providers/customer_provider.dart';
import 'package:amar_dokan/features/customers/presentation/widgets/customer_form.dart';
import 'package:amar_dokan/features/customers/presentation/screens/customer_details_screen.dart';
import 'package:amar_dokan/features/sales/providers/sale_provider.dart';
import 'package:amar_dokan/core/constants/app_colors.dart';

/// Customers Screen - Customer list with Firestore backend
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Firestore stream শুরু করি
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().startListening();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    CustomerModel customer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete "${customer.name}"?',
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

    if (confirmed == true && customer.id.isNotEmpty && context.mounted) {
      bool success = false;
    try {
      await context.read<CustomerProvider>().deleteCustomer(customer.id);
      success = true;
    } catch (_) {
      success = false;
    }
      if (context.mounted) {
        _showSnackBar(
          context,
          success
              ? 'Customer deleted successfully!'
              : 'Failed to delete customer',
          success ? AppColors.success : AppColors.error,
        );
      }
    }
  }

  // Add Customer Dialog
  Future<void> _showAddCustomerForm(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomerForm(
          onCancel: () => Navigator.of(ctx).pop(),
          onSubmit: (customer) async {
            bool success = false;
            try {
              await context.read<CustomerProvider>().addCustomer(customer);
              success = true;
            } catch (_) {
              success = false;
            }
            if (ctx.mounted) {
              Navigator.of(ctx).pop();
              if (context.mounted) {
                _showSnackBar(
                  context,
                  success ? 'Customer added!' : 'Failed to add',
                  success ? AppColors.success : AppColors.error,
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _navigateToDetails(BuildContext context, CustomerModel customer) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailsScreen(customer: customer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                context.read<CustomerProvider>().setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<CustomerProvider>().clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Customer list
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (context, provider, child) {
                // Loading state
                if (provider.isLoading && provider.customers.isEmpty) {
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

                final filtered = provider.filteredCustomers;

                // Empty state
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          provider.searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.people_outline,
                          size: 80,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.searchQuery.isNotEmpty
                              ? 'No customers match "${provider.searchQuery}"'
                              : 'No customers yet',
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.searchQuery.isEmpty
                              ? 'Tap + to add your first customer'
                              : 'Try a different search term',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Customer list
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final customer = filtered[index];
                    return Consumer<SaleProvider>(
                      builder: (context, saleProvider, _) {
                        final totalSpent = saleProvider.sales
                            .where((s) => s.customerId == customer.id)
                            .fold<double>(0.0, (sum, s) => sum + s.total);
                        final hasOrders = totalSpent > 0;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            onTap: () => _navigateToDetails(context, customer),
                            leading: CircleAvatar(
                              backgroundColor: customer.isActive
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              child: Text(
                                customer.initials,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              customer.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              customer.hasEmail
                                  ? '${customer.phone} • ${customer.email}'
                                  : customer.phone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: hasOrders
                                ? Text(
                                    '৳${totalSpent.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppColors.error,
                                    ),
                                    onPressed: () => _showDeleteDialog(
                                      context,
                                      customer,
                                    ),
                                  ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerForm(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
