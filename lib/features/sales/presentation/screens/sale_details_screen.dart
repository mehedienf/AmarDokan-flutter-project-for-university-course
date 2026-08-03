import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/sale_model.dart';
import '../../providers/sale_provider.dart';
import '../widgets/sale_item_card.dart';

class SaleDetailsScreen extends StatefulWidget {
  final SaleModel sale;

  const SaleDetailsScreen({super.key, required this.sale});

  @override
  State<SaleDetailsScreen> createState() => _SaleDetailsScreenState();
}

class _SaleDetailsScreenState extends State<SaleDetailsScreen> {
  late SaleModel _sale;

  @override
  void initState() {
    super.initState();
    _sale = widget.sale;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'partial':
        return AppColors.warning;
      case 'unpaid':
        return AppColors.error;
      case 'completed':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
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

  Future<void> _showSnackBar(String message, Color color) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sale?'),
        content: const Text(
          'This will permanently remove the sale and restore stock quantities. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteSale() async {
    final confirmed = await _confirmDelete();
    if (!confirmed || !mounted) return;
    final provider = context.read<SaleProvider>();
    final ok = await provider.deleteSale(_sale.id);
    if (!mounted) return;
    if (ok) {
      _showSnackBar('Sale deleted', AppColors.success);
      Navigator.pop(context, true);
    } else {
      _showSnackBar('Failed to delete sale', AppColors.error);
    }
  }

  Future<void> _showPaymentDialog() async {
    String selected = _sale.paymentStatus;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Update Payment Status'),
          content: RadioGroup<String>(
            groupValue: selected,
            onChanged: (v) => setLocal(() => selected = v ?? selected),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                RadioListTile<String>(
                  title: Text('Paid'),
                  value: 'paid',
                ),
                RadioListTile<String>(
                  title: Text('Partial'),
                  value: 'partial',
                ),
                RadioListTile<String>(
                  title: Text('Unpaid'),
                  value: 'unpaid',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted || result == _sale.paymentStatus) return;
    final provider = context.read<SaleProvider>();
    final paid = result == 'paid'
        ? _sale.total
        : result == 'unpaid'
            ? 0.0
            : (_sale.paidAmount > 0 && _sale.paidAmount < _sale.total
                ? _sale.paidAmount
                : _sale.total / 2);
    final updated = _sale.copyWith(paymentStatus: result, paidAmount: paid);
    final ok = await provider.updateSale(updated);
    if (!mounted) return;
    if (ok) {
      setState(() => _sale = updated);
      _showSnackBar('Payment status updated', AppColors.success);
    } else {
      _showSnackBar('Failed to update', AppColors.error);
    }
  }

  String _formatDate(DateTime d) {
    return DateFormat('dd MMM yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_sale.paymentStatus);
    final dateText = _sale.saleDate != null
        ? _formatDate(_sale.saleDate!)
        : _formatDate(_sale.createdAt);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_sale.invoiceNumber),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Print receipt',
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              _showSnackBar('Print preview coming soon', AppColors.info);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: Colors.white,
            onSelected: (v) {
              if (v == 'payment') _showPaymentDialog();
              if (v == 'delete') _deleteSale();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'payment',
                child: Row(
                  children: [
                    Icon(Icons.payments_outlined,
                        color: AppColors.textPrimary, size: 20),
                    SizedBox(width: 8),
                    Text('Update Payment'),
                  ],
                ),
              ),
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
      body: Column(
        children: [
          _buildHeader(statusColor, dateText),
          const Divider(height: 1),
          Expanded(child: _buildItemsList()),
          const Divider(height: 1),
          _buildTotals(),
        ],
      ),
    );
  }

  Widget _buildHeader(Color statusColor, String dateText) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _sale.hasCustomer
                          ? _sale.customerName!
                          : 'Walk-in Customer',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      _statusLabel(_sale.paymentStatus),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetaItem(Icons.calendar_today_outlined, 'Date', dateText),
              const SizedBox(width: 24),
              _buildMetaItem(Icons.payments_outlined, 'Method',
                  _sale.displayPaymentMethod),
              const SizedBox(width: 24),
              _buildMetaItem(Icons.shopping_bag_outlined, 'Items',
                  _sale.totalItems.toString()),
            ],
          ),
          if (_sale.hasNotes) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _sale.notes!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    if (_sale.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No items in this sale',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: _sale.items.length,
      itemBuilder: (ctx, i) {
        final item = _sale.items[i];
        return SaleItemCard(
          item: item,
          onQuantityChanged: (_) {/* read-only */},
          editable: false,
          showDiscountField: false,
        );
      },
    );
  }

  Widget _buildTotals() {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  _buildTotalRow('Subtotal', _sale.subtotal, false),
                  if (_sale.itemDiscount > 0)
                    _buildTotalRow('Item Discount', -_sale.itemDiscount, true),
                  if (_sale.extraDiscount > 0)
                    _buildTotalRow('Extra Discount', -_sale.extraDiscount, true),
                  if (_sale.tax > 0) _buildTotalRow('Tax', _sale.tax, false),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'BDT ${_sale.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (_sale.paidAmount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Paid',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'BDT ${_sale.paidAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Balance Due',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'BDT ${_sale.balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: _sale.balance > 0
                                ? AppColors.error
                                : AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_sale.totalProfit > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Profit',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'BDT ${_sale.totalProfit.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, bool isDiscount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'BDT ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              color: isDiscount ? AppColors.success : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
