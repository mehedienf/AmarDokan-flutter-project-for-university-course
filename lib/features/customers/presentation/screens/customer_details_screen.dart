import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/features/customers/data/models/customer_model.dart';
import 'package:amar_dokan/features/customers/providers/customer_provider.dart';
import 'package:amar_dokan/features/customers/presentation/screens/edit_customer_screen.dart';
import 'package:amar_dokan/features/sales/data/models/sale_model.dart';
import 'package:amar_dokan/features/sales/providers/sale_provider.dart';
import 'package:amar_dokan/core/constants/app_colors.dart';

/// Customer Details Screen
/// Customer এর সব info একসাথে দেখায় + Edit/Delete actions
///
/// Note: totalOrders / totalPurchases / lastPurchaseDate পুরনো persisted
/// fields যেগুলো কোথাও write হয় না। এই screen-এ আমরা SaleProvider থেকে
/// sales গুনে live aggregate করি, যাতে নতুন sale হলে totals তাৎক্ষণিকভাবে
/// refresh হয়।
class CustomerDetailsScreen extends StatefulWidget {
  final CustomerModel customer;

  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  CustomerModel get customer => widget.customer;

  // Delete confirmation
  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete "${customer.name}"?'),
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
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      bool success = false;
    try {
      await context.read<CustomerProvider>().deleteCustomer(customer.id);
      success = true;
    } catch (_) {
      success = false;
    }
      messenger.showSnackBar(
        SnackBar(
          content: Text(success ? 'Customer deleted!' : 'Failed to delete'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      if (success) {
        navigator.pop();
      }
    }
  }

  Future<void> _navigateToEdit(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditCustomerScreen(customer: customer),
      ),
    );

    // Edit থেকে updated customer back আসলে pop করি
    if (result == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
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
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildContactCard(),
            const SizedBox(height: 16),
            _buildPurchaseCard(),
            const SizedBox(height: 16),
            if (customer.hasNotes) ...[
              _buildNotesCard(),
              const SizedBox(height: 16),
            ],
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
                    label: const Text('Edit Customer'),
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
              backgroundColor: customer.isActive
                  ? AppColors.primary
                  : AppColors.textSecondary,
              child: Text(
                customer.initials,
                style: const TextStyle(
                  fontSize: 24,
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
                    customer.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customer.phone,
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
                      color: (customer.isActive
                              ? AppColors.success
                              : AppColors.textSecondary)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      customer.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        color: customer.isActive
                            ? AppColors.success
                            : AppColors.textSecondary,
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

  Widget _buildContactCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.contact_phone_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'Phone', customer.phone),
            if (customer.hasEmail) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.email_outlined, 'Email', customer.email!),
            ],
            if (customer.hasAddress) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.location_on_outlined, 'Address', customer.address!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseCard() {
    // Watch SaleProvider so totals refresh automatically when a sale is
    // added, updated, or removed.
    return Consumer<SaleProvider>(
      builder: (context, saleProvider, _) {
        final stats = _computePurchaseStats(saleProvider.sales);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Purchase Summary',
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
                      label: 'Total Orders',
                      value: '${stats.totalOrders}',
                      color: AppColors.primary,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                    ),
                    _buildStatBox(
                      label: 'Total Spent',
                      value: '৳${stats.totalSpent.toStringAsFixed(0)}',
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.event_outlined,
                  'Last Purchase',
                  stats.lastPurchaseDate != null
                      ? _formatDate(stats.lastPurchaseDate!)
                      : 'No purchases yet',
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Customer Since',
                  _formatDate(customer.createdAt),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Live aggregation: sum totals + count orders + find last sale date for
  /// this customer. Returns zeros / null when no matching sales exist.
  _PurchaseStats _computePurchaseStats(List<SaleModel> sales) {
    int totalOrders = 0;
    double totalSpent = 0.0;
    DateTime? lastPurchaseDate;
    final id = customer.id;
    for (final s in sales) {
      if (s.customerId != id) continue;
      totalOrders += 1;
      totalSpent += s.total;
      final d = s.saleDate ?? s.createdAt;
      if (lastPurchaseDate == null || d.isAfter(lastPurchaseDate)) {
        lastPurchaseDate = d;
      }
    }
    return _PurchaseStats(
      totalOrders: totalOrders,
      totalSpent: totalSpent,
      lastPurchaseDate: lastPurchaseDate,
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notes_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              customer.notes!,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
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
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Aggregated purchase stats for a single customer, computed live from
/// `SaleProvider`. Keeps the totals in sync with new sales without relying
/// on the (unmaintained) persisted `totalOrders` / `totalPurchases` fields.
class _PurchaseStats {
  final int totalOrders;
  final double totalSpent;
  final DateTime? lastPurchaseDate;

  const _PurchaseStats({
    required this.totalOrders,
    required this.totalSpent,
    required this.lastPurchaseDate,
  });
}
