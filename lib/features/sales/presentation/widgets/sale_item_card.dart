import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:amar_dokan/features/sales/data/models/sale_item_model.dart';
import 'package:amar_dokan/core/constants/app_colors.dart';

/// Reusable cart line item card.
class SaleItemCard extends StatefulWidget {
  final SaleItemModel item;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<double>? onDiscountChanged;
  final VoidCallback? onRemove;
  final bool editable;
  final bool showDiscountField;

  const SaleItemCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    this.onDiscountChanged,
    this.onRemove,
    this.editable = true,
    this.showDiscountField = false,
  });

  @override
  State<SaleItemCard> createState() => _SaleItemCardState();
}

class _SaleItemCardState extends State<SaleItemCard> {
  late final TextEditingController _discountController;

  @override
  void initState() {
    super.initState();
    _discountController = TextEditingController(
      text: widget.item.discount > 0
          ? widget.item.discount.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void didUpdateWidget(covariant SaleItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _discountController.text = widget.item.discount > 0
          ? widget.item.discount.toStringAsFixed(2)
          : '';
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  void _showDiscountDialog() {
    _discountController.text = widget.item.discount > 0
        ? widget.item.discount.toStringAsFixed(2)
        : '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Item Discount'),
        content: TextField(
          controller: _discountController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Discount (BDT)',
            hintText: '0.00',
            prefixIcon: Icon(Icons.local_offer_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value =
                  double.tryParse(_discountController.text.trim()) ?? 0.0;
              widget.onDiscountChanged?.call(value.clamp(0, double.infinity));
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.sku != null && item.sku!.isNotEmpty)
                        Text(
                          'SKU: ${item.sku}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.editable && widget.onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.error,
                    tooltip: 'Remove',
                    onPressed: widget.onRemove,
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.unitPrice.toStringAsFixed(2)} BDT x ${item.quantity}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Subtotal: ${item.subtotal.toStringAsFixed(2)} BDT',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.editable)
                  _buildQtyStepper(item.quantity)
                else
                  Text(
                    'Qty: ${item.quantity}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),

            // Discount row
            if (widget.editable && widget.showDiscountField) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showDiscountDialog,
                      icon: const Icon(Icons.local_offer_outlined, size: 16),
                      label: Text(
                        item.discount > 0
                            ? 'Discount: ${item.discount.toStringAsFixed(2)} BDT'
                            : 'Add Discount',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: item.discount > 0
                            ? AppColors.success
                            : AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Line total row
            if (item.discount > 0 || item.total != item.subtotal) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Line Total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${item.total.toStringAsFixed(2)} BDT',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQtyStepper(int currentQty) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: currentQty > 1
                ? () => widget.onQuantityChanged(currentQty - 1)
                : null,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            alignment: Alignment.center,
            child: Text(
              '$currentQty',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () => widget.onQuantityChanged(currentQty + 1),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
