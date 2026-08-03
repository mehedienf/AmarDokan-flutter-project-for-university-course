import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/features/suppliers/data/models/supplier_model.dart';
import 'package:amar_dokan/features/suppliers/providers/supplier_provider.dart';
import 'package:amar_dokan/features/suppliers/presentation/screens/edit_supplier_screen.dart';
import 'package:amar_dokan/core/constants/app_colors.dart';

/// Supplier Details Screen - Shows complete supplier information
class SupplierDetailsScreen extends StatelessWidget {
  final SupplierModel supplier;

  const SupplierDetailsScreen({super.key, required this.supplier});

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text(
          'Are you sure you want to delete "${supplier.displayName}"? This action cannot be undone.',
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
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Supplier deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete supplier'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _openPhoneDialer(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${supplier.phone}...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _sendEmail(BuildContext context) {
    if (!supplier.hasEmail) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Composing email to ${supplier.email}...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _openWebsite(BuildContext context) {
    if (!supplier.hasWebsite) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${supplier.website}...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditSupplierScreen(supplier: supplier),
                ),
              );
            },
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card - Company avatar + status
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: supplier.isActive
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      child: Text(
                        supplier.companyInitial,
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
                            supplier.displayName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (supplier.companyName.isNotEmpty &&
                              supplier.name.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              supplier.name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: supplier.isActive
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              supplier.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: supplier.isActive
                                    ? AppColors.success
                                    : AppColors.error,
                                fontSize: 12,
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
            ),
            const SizedBox(height: 16),

            // Contact Information Card
            const _SectionHeader(title: 'Contact Information'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.phone, color: AppColors.primary),
                    title: const Text('Phone'),
                    subtitle: Text(supplier.phone),
                    trailing: IconButton(
                      icon: const Icon(Icons.call),
                      onPressed: () => _openPhoneDialer(context),
                    ),
                  ),
                  if (supplier.hasEmail)
                    ListTile(
                      leading: const Icon(Icons.email, color: AppColors.primary),
                      title: const Text('Email'),
                      subtitle: Text(supplier.email!),
                      trailing: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => _sendEmail(context),
                      ),
                    ),
                  if (supplier.hasAddress)
                    ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                      ),
                      title: const Text('Address'),
                      subtitle: Text(supplier.address!),
                    ),
                  if (supplier.hasWebsite)
                    ListTile(
                      leading: const Icon(
                        Icons.language,
                        color: AppColors.primary,
                      ),
                      title: const Text('Website'),
                      subtitle: Text(supplier.website!),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => _openWebsite(context),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Purchase Summary Card
            const _SectionHeader(title: 'Purchase Summary'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Total Spent',
                            value:
                                '৳${supplier.totalPurchases.toStringAsFixed(0)}',
                            color: AppColors.primary,
                            icon: Icons.payments,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: AppColors.textSecondary.withValues(alpha: 0.2),
                        ),
                        Expanded(
                          child: _StatTile(
                            label: 'Products Supplied',
                            value: '${supplier.productsSupplied}',
                            color: AppColors.success,
                            icon: Icons.inventory_2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (supplier.lastPurchaseDate != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Last purchase: ${_formatDate(supplier.lastPurchaseDate!)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    else
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'No purchases yet',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes Card
            if (supplier.hasNotes) ...[
              const _SectionHeader(title: 'Notes'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    supplier.notes!,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Metadata Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Metadata',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Added: ${_formatDate(supplier.createdAt)}'),
                    Text('Updated: ${_formatDate(supplier.updatedAt)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteDialog(context),
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              EditSupplierScreen(supplier: supplier),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
