import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/purchase_model.dart';
import '../../providers/purchase_provider.dart';
import '../widgets/purchase_card.dart';
import 'add_purchase_screen.dart';
import 'purchase_details_screen.dart';

/// PurchaseScreen - All purchases with filters.
///
/// Shows real-time Firestore purchases list with:
/// - Text search (invoice, supplier, supplier invoice, notes)
/// - Status filter (completed / pending / cancelled)
/// - Payment status filter (paid / partial / unpaid)
/// - Date range filter
class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PurchaseProvider>();
      provider.startListening();
      _searchController.text = provider.searchQuery;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _showDeleteDialog(PurchaseModel purchase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Purchase'),
        content: Text(
          'Are you sure you want to delete "${purchase.invoiceNumber}"? '
          'Stock quantities will be restored automatically.',
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

    if (confirmed == true && mounted) {
      final success =
          await context.read<PurchaseProvider>().deletePurchase(purchase.id);
      if (!mounted) return;
      _showSnackBar(
        success ? 'Purchase deleted (stock restored)' : 'Failed to delete',
        success ? AppColors.success : AppColors.error,
      );
    }
  }

  Future<void> _pickDateRange() async {
    final provider = context.read<PurchaseProvider>();
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
          provider.hasDateFilter && provider.startDate != null
              ? DateTimeRange(
                  start: provider.startDate!,
                  end: provider.endDate ?? provider.startDate!,
                )
              : null,
    );

    if (picked != null) {
      provider.setDateRange(picked.start, picked.end);
    }
  }

  void _navigateToDetails(PurchaseModel purchase) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PurchaseDetailsScreen(purchaseId: purchase.id),
      ),
    );
  }

  Future<void> _navigateToCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddPurchaseScreen(),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                context.read<PurchaseProvider>().setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Search invoice, supplier, or notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<PurchaseProvider>().clearSearch();
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
          Consumer<PurchaseProvider>(
            builder: (context, provider, _) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: provider.hasDateFilter
                          ? '${_formatDate(provider.startDate!)} - ${_formatDate(provider.endDate!)}'
                          : 'Date Range',
                      icon: Icons.calendar_today_outlined,
                      isActive: provider.hasDateFilter,
                      onTap: _pickDateRange,
                      onClear: provider.hasDateFilter
                          ? () => provider.clearDateRange()
                          : null,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: provider.hasStatusFilter
                          ? 'Status: ${provider.statusFilter!.toUpperCase()}'
                          : 'All Statuses',
                      icon: Icons.flag_outlined,
                      isActive: provider.hasStatusFilter,
                      onTap: () => _showStatusSheet(provider),
                      onClear: provider.hasStatusFilter
                          ? () => provider.clearStatusFilter()
                          : null,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: provider.hasPaymentFilter
                          ? 'Pay: ${provider.paymentStatusFilter!.toUpperCase()}'
                          : 'All Payments',
                      icon: Icons.payment_outlined,
                      isActive: provider.hasPaymentFilter,
                      onTap: () => _showPaymentStatusSheet(provider),
                      onClear: provider.hasPaymentFilter
                          ? () => provider.clearPaymentStatusFilter()
                          : null,
                    ),
                    if (provider.hasDateFilter ||
                        provider.hasStatusFilter ||
                        provider.hasPaymentFilter) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => provider.clearAllFilters(),
                        icon: const Icon(
                          Icons.filter_alt_off_outlined,
                          size: 18,
                        ),
                        label: const Text('Clear'),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Consumer<PurchaseProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.purchases.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
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
                    ),
                  );
                }
                final purchases = provider.filteredPurchases;
                if (purchases.isEmpty) {
                  return _buildEmptyState(provider);
                }
                return RefreshIndicator(
                  onRefresh: () async => provider.startListening(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96, top: 4),
                    itemCount: purchases.length,
                    itemBuilder: (ctx, i) {
                      final p = purchases[i];
                      return PurchaseCard(
                        purchase: p,
                        onTap: () => _navigateToDetails(p),
                        onDelete: () => _showDeleteDialog(p),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Purchase'),
      ),
    );
  }

  Widget _buildEmptyState(PurchaseProvider provider) {
    final hasFilters = provider.searchQuery.isNotEmpty ||
        provider.hasDateFilter ||
        provider.hasStatusFilter ||
        provider.hasPaymentFilter;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters
                  ? Icons.search_off_outlined
                  : Icons.shopping_bag_outlined,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No matching purchases' : 'No purchases yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try changing your search or filters'
                  : 'Record your first purchase by tapping the button below',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final bgColor = isActive ? AppColors.primary : Colors.white;
    final fgColor = isActive ? Colors.white : AppColors.textPrimary;
    final borderColor = isActive ? AppColors.primary : AppColors.divider;
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fgColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: fgColor,
                ),
              ),
              if (onClear != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 14, color: fgColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusSheet(PurchaseProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Filter by Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(height: 1),
            _buildOption(
              ctx,
              provider.setStatusFilter,
              provider.statusFilter,
              null,
              'All Statuses',
              Icons.all_inclusive,
              AppColors.textSecondary,
            ),
            _buildOption(
              ctx,
              provider.setStatusFilter,
              provider.statusFilter,
              'completed',
              'Completed',
              Icons.check_circle_outline,
              AppColors.success,
            ),
            _buildOption(
              ctx,
              provider.setStatusFilter,
              provider.statusFilter,
              'pending',
              'Pending',
              Icons.hourglass_empty,
              AppColors.warning,
            ),
            _buildOption(
              ctx,
              provider.setStatusFilter,
              provider.statusFilter,
              'cancelled',
              'Cancelled',
              Icons.cancel_outlined,
              AppColors.error,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPaymentStatusSheet(PurchaseProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Filter by Payment Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(height: 1),
            _buildOption(
              ctx,
              provider.setPaymentStatusFilter,
              provider.paymentStatusFilter,
              null,
              'All Payments',
              Icons.all_inclusive,
              AppColors.textSecondary,
            ),
            _buildOption(
              ctx,
              provider.setPaymentStatusFilter,
              provider.paymentStatusFilter,
              'paid',
              'Paid',
              Icons.check_circle_outline,
              AppColors.success,
            ),
            _buildOption(
              ctx,
              provider.setPaymentStatusFilter,
              provider.paymentStatusFilter,
              'partial',
              'Partial',
              Icons.pie_chart_outline,
              AppColors.warning,
            ),
            _buildOption(
              ctx,
              provider.setPaymentStatusFilter,
              provider.paymentStatusFilter,
              'unpaid',
              'Unpaid',
              Icons.error_outline,
              AppColors.error,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext ctx,
    void Function(String?) setter,
    String? current,
    String? value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = current == value;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        setter(value);
        Navigator.pop(ctx);
      },
    );
  }
}