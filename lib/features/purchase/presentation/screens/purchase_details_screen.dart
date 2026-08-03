import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/purchase_item_model.dart';
import '../../data/models/purchase_model.dart';
import '../../providers/purchase_provider.dart';

/// Read-only details view for a single purchase.
class PurchaseDetailsScreen extends StatelessWidget {
  final String purchaseId;
  const PurchaseDetailsScreen({super.key, required this.purchaseId});

  @override
  Widget build(BuildContext context) {
    return Consumer<PurchaseProvider>(
      builder: (ctx, provider, _) {
        final purchase = provider.getPurchaseById(purchaseId);
        if (purchase == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Purchase Details')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This purchase no longer exists.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          );
        }
        return _buildScaffold(context, purchase);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, PurchaseModel p) {
    return Scaffold(
      appBar: AppBar(
        title: Text(p.invoiceNumber),
        actions: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, p),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _buildHeader(p),
          const SizedBox(height: 12),
          _buildSupplier(p),
          const SizedBox(height: 12),
          _buildItemsCard(p),
          const SizedBox(height: 12),
          _buildTotalsCard(p),
          const SizedBox(height: 12),
          _buildPaymentCard(p),
          if (p.hasNotes) ...[
            const SizedBox(height: 12),
            _buildNotesCard(p),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, PurchaseModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Purchase?'),
        content: Text(
          'This will delete ${p.invoiceNumber} and reverse stock for ${p.totalItems} unit(s).',
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
    if (ok != true) return;
    if (!context.mounted) return;
    final provider = context.read<PurchaseProvider>();
    final res = await provider.deletePurchase(p.id);
    if (!context.mounted) return;
    if (res) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase deleted'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Failed to delete',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ============================================
  // Sections
  // ============================================

  Widget _buildHeader(PurchaseModel p) {
    final statusColor = _statusColor(p);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.invoiceNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'BDT ${p.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(p, statusColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Purchased: ${_fmt(p.purchaseDate)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (p.hasExpectedDelivery) ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Due: ${_fmt(p.expectedDeliveryDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupplier(PurchaseModel p) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(
            p.hasSupplier ? Icons.local_shipping_outlined : Icons.store,
            color: Colors.white,
          ),
        ),
        title: Text(
          p.hasSupplier ? p.supplierName! : 'Direct Purchase',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: p.hasSupplierInvoice
            ? Text(
                'Supplier Invoice: ${p.supplierInvoice}',
                style: const TextStyle(fontSize: 12),
              )
            : null,
      ),
    );
  }

  Widget _buildItemsCard(PurchaseModel p) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Items',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${p.totalItems} units / ${p.uniqueProducts} products',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...p.items.map((it) => _itemTile(it)),
          ],
        ),
      ),
    );
  }

  Widget _itemTile(PurchaseItemModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (item.sku != null && item.sku!.isNotEmpty)
                  Text(
                    'SKU: ${item.sku}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity} × BDT ${item.unitPrice.toStringAsFixed(2)}'
                  '${item.discount > 0 ? '  (−BDT ${item.discount.toStringAsFixed(2)})' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'BDT ${item.total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(PurchaseModel p) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _row('Subtotal', p.subtotal),
            if (p.itemDiscount > 0)
              _row('Item Discount', -p.itemDiscount, color: AppColors.error),
            if (p.hasDiscount)
              _row('Extra Discount', -p.extraDiscount, color: AppColors.error),
            if (p.tax > 0) _row('Tax', p.tax),
            if (p.hasShipping) _row('Shipping', p.shippingCost),
            const Divider(height: 16),
            _row('Total', p.total, bold: true, fontSize: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(PurchaseModel p) {
    final statusColor = _paymentColor(p);
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Method',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        p.displayPaymentMethod,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p.isPaid
                        ? 'Paid'
                        : p.isPartial
                            ? 'Partial'
                            : 'Unpaid',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _miniStat('Paid', p.paidAmount, AppColors.success)),
                Expanded(child: _miniStat('Due', p.dueAmount, AppColors.error)),
                Expanded(
                  child: _miniStat(
                    'Expected Profit',
                    p.totalExpectedProfit,
                    AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(PurchaseModel p) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              p.notes!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // Helpers
  // ============================================

  Widget _row(
    String label,
    double value, {
    bool bold = false,
    double fontSize = 13,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            'BDT ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, double v, Color color) {
    return Column(
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
          'BDT ${v.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(PurchaseModel p, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        p.displayStatus,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _statusColor(PurchaseModel p) {
    if (p.isCompleted) return AppColors.success;
    if (p.isCancelled) return AppColors.error;
    return AppColors.warning;
  }

  Color _paymentColor(PurchaseModel p) {
    if (p.isPaid) return AppColors.success;
    if (p.isPartial) return AppColors.warning;
    return AppColors.error;
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
}
