import 'package:flutter/material.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';
import 'package:amar_dokan/features/accounting/data/models/transaction_model.dart';

/// A single transaction list-item card.
///
/// Shows the category icon, category label, party name, date, and signed amount
/// (green for income, red for expense). Tap invokes [onTap].
class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onLongPress,
  });

  IconData _iconFromName(String name) {
    const fallback = Icons.circle_outlined;
    switch (name) {
      case 'point_of_sale':
        return const IconData(0xe54f, fontFamily: 'MaterialIcons');
      case 'attach_money':
        return const IconData(0xe227, fontFamily: 'MaterialIcons');
      case 'account_balance':
        return const IconData(0xe84f, fontFamily: 'MaterialIcons');
      case 'payments':
        return const IconData(0xef63, fontFamily: 'MaterialIcons');
      case 'people':
        return const IconData(0xe7ef, fontFamily: 'MaterialIcons');
      case 'undo':
        return const IconData(0xe166, fontFamily: 'MaterialIcons');
      case 'shopping_bag':
        return const IconData(0xf1cc, fontFamily: 'MaterialIcons');
      case 'home_work':
        return const IconData(0xea09, fontFamily: 'MaterialIcons');
      case 'badge':
        return const IconData(0xea67, fontFamily: 'MaterialIcons');
      case 'bolt':
        return const IconData(0xe1a7, fontFamily: 'MaterialIcons');
      case 'local_shipping':
        return const IconData(0xe558, fontFamily: 'MaterialIcons');
      case 'campaign':
        return const IconData(0xe545, fontFamily: 'MaterialIcons');
      case 'build':
        return const IconData(0xe869, fontFamily: 'MaterialIcons');
      case 'receipt_long':
        return const IconData(0xefdc, fontFamily: 'MaterialIcons');
      case 'person_remove':
        return const IconData(0xe7f3, fontFamily: 'MaterialIcons');
      case 'request_quote':
        return const IconData(0xf01b, fontFamily: 'MaterialIcons');
      case 'store':
        return const IconData(0xe8d1, fontFamily: 'MaterialIcons');
      case 'currency_exchange':
        return const IconData(0xeb70, fontFamily: 'MaterialIcons');
      default:
        return fallback;
    }
  }

  Color _typeColor() {
    return transaction.isIncome ? AppColors.success : AppColors.error;
  }

  String _formatAmount() {
    final sign = transaction.isIncome ? '+' : '-';
    final value = transaction.amount.toStringAsFixed(2);
    return '$sign ৳$value';
  }

  String _formatDate() {
    final d = transaction.transactionDate;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year} • $hh:$mm';
  }

  String _subtitleText() {
    final party = transaction.partyName;
    if (party != null && party.isNotEmpty) return party;
    final desc = transaction.description;
    if (desc != null && desc.isNotEmpty) return desc;
    return transaction.referenceNumber;
  }
  @override
  Widget build(BuildContext context) {
    final color = _typeColor();
    final iconData = _iconFromName(transaction.category.iconName);
    final subtitle = _subtitleText();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            transaction.category.label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatAmount(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatDate(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    if (transaction.hasReference) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.link,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              transaction.referenceLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}
