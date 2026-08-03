import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';
import 'package:amar_dokan/features/accounting/data/models/transaction_model.dart';
import 'package:amar_dokan/features/accounting/providers/transaction_provider.dart';

/// TransactionDetailsScreen - Read-only detail view for one transaction.
///
/// Loads the transaction via TransactionProvider.getTransaction on
/// first build. Shows every field plus a delete button (with confirm
/// dialog). Pops `true` when deleted so the list screen can refresh.
class TransactionDetailsScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailsScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  TransactionModel? _transaction;
  bool _isLoading = true;
  String? _error;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final provider = context.read<TransactionProvider>();
      final tx = await provider.getTransaction(widget.transactionId);
      if (!mounted) return;
      setState(() {
        _transaction = tx;
        _isLoading = false;
        _error = tx == null ? 'Transaction not found' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteWithConfirm() async {
    final tx = _transaction;
    if (tx == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text(
          'This will permanently delete ${tx.referenceNumber} '
          '(${tx.type.label} • ৳${tx.amount.toStringAsFixed(2)}).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await context.read<TransactionProvider>().deleteTransaction(tx.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Color _typeColor() {
    final tx = _transaction;
    if (tx == null) return AppColors.textSecondary;
    return tx.isIncome ? AppColors.success : AppColors.error;
  }

  IconData _typeIcon() {
    final tx = _transaction;
    if (tx == null) return Icons.swap_horiz;
    return tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward;
  }

  @override
  Widget build(BuildContext context) {
    final tx = _transaction;

    return Scaffold(
      appBar: AppBar(
        title: Text(tx == null ? 'Transaction' : tx.referenceNumber),
        actions: [
          if (tx != null)
            IconButton(
              tooltip: 'Delete',
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_outline),
              onPressed: _isDeleting ? null : _deleteWithConfirm,
            ),
        ],
      ),
      body: _buildBody(tx),
    );
  }

  Widget _buildBody(TransactionModel? tx) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _load();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (tx == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildHeaderCard(tx),
        const SizedBox(height: 16),
        _buildSection(
          title: 'Details',
          children: [
            _infoRow(
              icon: Icons.swap_horiz,
              label: 'Type',
              value: tx.type.label,
              valueColor: _typeColor(),
            ),
            _infoRow(
              icon: _iconFromName(tx.category.iconName),
              label: 'Category',
              value: tx.category.label,
            ),
            _infoRow(
              icon: Icons.payments_outlined,
              label: 'Payment method',
              value: tx.displayPaymentMethod,
            ),
            _infoRow(
              icon: Icons.event,
              label: 'Date',
              value: _formatDate(tx.transactionDate),
            ),
            _infoRow(
              icon: Icons.tag,
              label: 'Reference',
              value: tx.referenceNumber,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSection(
          title: 'Party',
          children: [
            _infoRow(
              icon: tx.isIncome
                  ? Icons.person_outline
                  : Icons.local_shipping_outlined,
              label: tx.isIncome ? 'Customer' : 'Supplier',
              value: tx.partyName ?? '—',
            ),
            if (tx.partyId != null)
              _infoRow(
                icon: Icons.fingerprint,
                label: 'Party ID',
                value: tx.partyId!,
              ),
          ],
        ),
        if (tx.hasDescription || tx.hasNotes) ...[
          const SizedBox(height: 16),
          _buildSection(
            title: 'Notes',
            children: [
              if (tx.hasDescription)
                _infoRow(
                  icon: Icons.notes,
                  label: 'Description',
                  value: tx.description!,
                ),
              if (tx.hasNotes)
                _infoRow(
                  icon: Icons.sticky_note_2_outlined,
                  label: 'Notes',
                  value: tx.notes!,
                ),
            ],
          ),
        ],
        if (tx.hasReference) ...[
          const SizedBox(height: 16),
          _buildSection(
            title: 'Link',
            children: [
              _infoRow(
                icon: Icons.link,
                label: tx.referenceLabel,
                value: tx.referenceId!,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHeaderCard(TransactionModel tx) {
    final color = _typeColor();
    final sign = tx.isIncome ? '+' : '-';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.20),
                child: Icon(_typeIcon(), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.type.label.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.category.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '$sign৳${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(tx.transactionDate),
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.15),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'shopping_cart':
        return const IconData(0xe547, fontFamily: 'MaterialIcons');
      case 'local_shipping':
        return const IconData(0xe558, fontFamily: 'MaterialIcons');
      case 'inventory_2':
        return const IconData(0xe179, fontFamily: 'MaterialIcons');
      case 'receipt_long':
        return const IconData(0xe532, fontFamily: 'MaterialIcons');
      case 'home':
        return const IconData(0xe88a, fontFamily: 'MaterialIcons');
      case 'bolt':
        return const IconData(0xe1ac, fontFamily: 'MaterialIcons');
      case 'water_drop':
        return const IconData(0xe798, fontFamily: 'MaterialIcons');
      case 'groups':
        return const IconData(0xe7ef, fontFamily: 'MaterialIcons');
      case 'campaign':
        return const IconData(0xe539, fontFamily: 'MaterialIcons');
      case 'miscellaneous_services':
        return const IconData(0xe8d8, fontFamily: 'MaterialIcons');
      case 'payments':
        return const IconData(0xe4c7, fontFamily: 'MaterialIcons');
      case 'storefront':
        return const IconData(0xe569, fontFamily: 'MaterialIcons');
      case 'handshake':
        return const IconData(0xebcb, fontFamily: 'MaterialIcons');
      case 'card_giftcard':
        return const IconData(0xe8f6, fontFamily: 'MaterialIcons');
      case 'account_balance':
        return const IconData(0xe84f, fontFamily: 'MaterialIcons');
      case 'savings':
        return const IconData(0xf01c1, fontFamily: 'MaterialIcons');
      case 'request_quote':
        return const IconData(0xe7ee, fontFamily: 'MaterialIcons');
      case 'work':
        return const IconData(0xe943, fontFamily: 'MaterialIcons');
      case 'point_of_sale':
        return const IconData(0xe54e, fontFamily: 'MaterialIcons');
      case 'money':
        return const IconData(0xe263, fontFamily: 'MaterialIcons');
      case 'undo':
        return const IconData(0xe166, fontFamily: 'MaterialIcons');
      case 'shopping_bag':
        return const IconData(0xe547, fontFamily: 'MaterialIcons');
      case 'badge':
        return const IconData(0xea67, fontFamily: 'MaterialIcons');
      case 'build':
        return const IconData(0xe869, fontFamily: 'MaterialIcons');
      case 'gavel':
        return const IconData(0xe85e, fontFamily: 'MaterialIcons');
      case 'person':
        return const IconData(0xe7fd, fontFamily: 'MaterialIcons');
      case 'money_off':
        return const IconData(0xe1ec, fontFamily: 'MaterialIcons');
      case 'inventory':
        return const IconData(0xe179, fontFamily: 'MaterialIcons');
      default:
        return const IconData(0xe88a, fontFamily: 'MaterialIcons');
    }
  }
}
