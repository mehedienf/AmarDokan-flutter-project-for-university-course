import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/features/sales/data/models/sale_model.dart';
import 'package:amar_dokan/features/sales/providers/sale_provider.dart';
import 'package:amar_dokan/features/sales/presentation/screens/sale_details_screen.dart';
import 'package:amar_dokan/features/sales/presentation/screens/create_sale_screen.dart';
import 'package:amar_dokan/core/constants/app_colors.dart';

/// Sales Screen - All sales with filters
///
/// Shows real-time Firestore sales list with:
/// - Text search (invoice, customer, notes)
/// - Payment status filter
/// - Date range filter
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SaleProvider>();
      provider.startListening();
      // Initialise filter display strings from provider state if any
      _searchController.text = provider.searchQuery;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _showDeleteDialog(SaleModel sale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sale'),
        content: Text(
          'Are you sure you want to delete sale "${sale.invoiceNumber}"? '
          'Stock will not be automatically restored.',
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
          await context.read<SaleProvider>().deleteSale(sale.id);
      if (!mounted) return;
      _showSnackBar(
        success ? 'Sale deleted!' : 'Failed to delete sale',
        success ? AppColors.success : AppColors.error,
      );
    }
  }

  Future<void> _pickDateRange() async {
    final provider = context.read<SaleProvider>();
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

  void _navigateToDetails(SaleModel sale) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SaleDetailsScreen(sale: sale),
      ),
    );
  }

  Future<void> _navigateToCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateSaleScreen(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'partial':
        return AppColors.warning;
      case 'unpaid':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
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
                context.read<SaleProvider>().setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Search invoice, customer, or notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<SaleProvider>().clearSearch();
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

          // Filter chips row
          Consumer<SaleProvider>(
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
                      label: provider.hasPaymentFilter
                          ? 'Status: ${provider.paymentStatusFilter!.toUpperCase()}'
                          : 'All Statuses',
                      icon: Icons.payment_outlined,
                      isActive: provider.hasPaymentFilter,
                      onTap: () => _showPaymentStatusSheet(provider),
                      onClear: provider.hasPaymentFilter
                          ? () => provider.clearPaymentStatusFilter()
                          : null,
                    ),
                    if (provider.hasDateFilter || provider.hasPaymentFilter) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => provider.clearAllFilters(),
                        icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                        label: const Text('Clear'),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 4),

          // List area
          Expanded(
            child: Consumer<SaleProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.sales.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sales = provider.filteredSales;
                if (sales.isEmpty) {
                  return _buildEmptyState(provider);
                }
                return RefreshIndicator(
                  onRefresh: () async => provider.startListening(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96, top: 4),
                    itemCount: sales.length,
                    itemBuilder: (ctx, i) => _buildSaleTile(sales[i], provider),
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
        label: const Text('New Sale'),
      ),
    );
  }

  Widget _buildEmptyState(SaleProvider provider) {
    final hasFilters = provider.searchQuery.isNotEmpty ||
        provider.hasDateFilter ||
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
                  : Icons.receipt_long_outlined,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No matching sales' : 'No sales yet',
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
                  : 'Create your first sale by tapping the button below',
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

  void _showPaymentStatusSheet(SaleProvider provider) {
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
            _buildStatusOption(ctx, provider, null, 'All Statuses',
                Icons.all_inclusive, AppColors.textSecondary),
            _buildStatusOption(ctx, provider, 'paid', 'Paid',
                Icons.check_circle_outline, AppColors.success),
            _buildStatusOption(ctx, provider, 'partial', 'Partial',
                Icons.pie_chart_outline, AppColors.warning),
            _buildStatusOption(ctx, provider, 'unpaid', 'Unpaid',
                Icons.error_outline, AppColors.error),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    BuildContext ctx,
    SaleProvider provider,
    String? status,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = provider.paymentStatusFilter == status;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: isSelected ? Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        provider.setPaymentStatusFilter(status);
        Navigator.pop(ctx);
      },
    );
  }

  Widget _buildSaleTile(SaleModel sale, SaleProvider provider) {
    final statusColor = _statusColor(sale.paymentStatus);
    final statusLabel = _statusLabel(sale.paymentStatus);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: () => _navigateToDetails(sale),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt_outlined, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.invoiceNumber,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sale.hasCustomer ? sale.customerName! : 'Walk-in Customer',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'BDT ${sale.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    color: Colors.white,
                    onSelected: (v) {
                      if (v == 'delete') _showDeleteDialog(sale);
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                color: AppColors.error, size: 20),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    sale.saleDate != null ? _formatDate(sale.saleDate!) : _formatDate(sale.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.shopping_bag_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${sale.totalItems} item${sale.totalItems == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (sale.paymentMethod.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.payments_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      sale.displayPaymentMethod,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              if (sale.hasNotes) ...[
                const SizedBox(height: 6),
                Text(
                  sale.notes!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'partial':
        return 'Partial';
      case 'unpaid':
        return 'Unpaid';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }
}
