import 'package:flutter/material.dart';

import 'package:amar_dokan/features/sales/data/models/sale_model.dart';
import 'package:amar_dokan/core/constants/app_colors.dart';

/// Sticky bottom summary panel for the POS / create-sale screen.
///
/// Shows subtotal, discount, tax, total, and a primary action button.
/// All values are derived from a [SaleModel]; updates are pushed up via
/// the [onChanged] callback so the parent can rebuild its state.
class SaleSummary extends StatelessWidget {
  final SaleModel sale;
  final String primaryButtonLabel;
  final IconData primaryButtonIcon;
  final VoidCallback? onPrimaryPressed;
  final bool enabled;

  const SaleSummary({
    super.key,
    required this.sale,
    required this.primaryButtonLabel,
    required this.primaryButtonIcon,
    this.onPrimaryPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRow(
                label: 'Subtotal',
                value: sale.subtotal,
                color: AppColors.textPrimary,
              ),
              if (sale.itemDiscount > 0) ...[
                const SizedBox(height: 4),
                _buildRow(
                  label: 'Item Discount',
                  value: -sale.itemDiscount,
                  color: AppColors.success,
                ),
              ],
              if (sale.extraDiscount > 0) ...[
                const SizedBox(height: 4),
                _buildRow(
                  label: 'Extra Discount',
                  value: -sale.extraDiscount,
                  color: AppColors.success,
                ),
              ],
              if (sale.tax > 0) ...[
                const SizedBox(height: 4),
                _buildRow(
                  label: 'Tax',
                  value: sale.tax,
                  color: AppColors.textPrimary,
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
              _buildRow(
                label: 'Total',
                value: sale.total,
                color: AppColors.primary,
                isBold: true,
                fontSize: 18,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      (enabled && onPrimaryPressed != null && sale.items.isNotEmpty)
                          ? onPrimaryPressed
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.textSecondary.withValues(
                      alpha: 0.3,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(primaryButtonIcon),
                  label: Text(
                    primaryButtonLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required double value,
    required Color color,
    bool isBold = false,
    double fontSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: AppColors.textSecondary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '${value.toStringAsFixed(2)} BDT',
          style: TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
