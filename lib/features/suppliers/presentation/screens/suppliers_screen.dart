import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/features/suppliers/data/models/supplier_model.dart';
import 'package:amar_dokan/features/suppliers/providers/supplier_provider.dart';
import 'package:amar_dokan/features/suppliers/presentation/widgets/supplier_form.dart';
import 'package:amar_dokan/features/suppliers/presentation/screens/supplier_details_screen.dart';
import 'package:amar_dokan/core/constants/app_colors.dart';

/// Suppliers Screen - Supplier list with Firestore backend
class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().startListening();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    SupplierModel supplier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text(
          'Are you sure you want to delete "${supplier.displayName}"?',
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

    if (confirmed == true && supplier.id.isNotEmpty && context.mounted) {
      bool success = false;
    try {
      await context.read<SupplierProvider>().deleteSupplier(supplier.id);
      success = true;
    } catch (_) {
      success = false;
    }
      if (context.mounted) {
        _showSnackBar(
          context,
          success ? 'Supplier deleted successfully!' : 'Failed to delete supplier',
          success ? AppColors.success : AppColors.error,
        );
      }
    }
  }

  Future<void> _showAddSupplierForm(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          child: SupplierForm(
            onCancel: () => Navigator.of(ctx).pop(),
            onSubmit: (supplier) async {
              bool success = false;
    try {
      await context.read<SupplierProvider>().addSupplier(supplier);
      success = true;
    } catch (_) {
      success = false;
    }
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                if (context.mounted) {
                  _showSnackBar(
                    context,
                    success ? 'Supplier added!' : 'Failed to add',
                    success ? AppColors.success : AppColors.error,
                  );
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToDetails(
    BuildContext context,
    SupplierModel supplier,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupplierDetailsScreen(supplier: supplier),
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
                context.read<SupplierProvider>().setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Search by company, name, or phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<SupplierProvider>().clearSearch();
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

          // Supplier list
          Expanded(
            child: Consumer<SupplierProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.suppliers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

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

                final filtered = provider.filteredSuppliers;

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          provider.searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.local_shipping_outlined,
                          size: 80,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.searchQuery.isNotEmpty
                              ? 'No suppliers match "${provider.searchQuery}"'
                              : 'No suppliers yet',
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.searchQuery.isEmpty
                              ? 'Tap + to add your first supplier'
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

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final supplier = filtered[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        onTap: () => _navigateToDetails(context, supplier),
                        leading: CircleAvatar(
                          backgroundColor: supplier.isActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          child: Text(
                            supplier.companyInitial,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          supplier.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          supplier.hasAddress
                              ? '${supplier.name} • ${supplier.address}'
                              : supplier.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: supplier.hasSupplied
                            ? Text(
                                '৳${supplier.totalPurchases.toStringAsFixed(0)}',
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
                                onPressed: () =>
                                    _showDeleteDialog(context, supplier),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSupplierForm(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
