import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';
import 'package:amar_dokan/features/accounting/data/models/transaction_model.dart';
import 'package:amar_dokan/features/accounting/presentation/widgets/transaction_card.dart';
import 'package:amar_dokan/features/accounting/providers/transaction_provider.dart';

import 'add_transaction_screen.dart';
import 'transaction_details_screen.dart';

/// AccountingScreen - All income/expense transactions.
///
/// Shows real-time Firestore transactions list with:
/// - Summary header (Income / Expense / Net)
/// - Type filter chips (All / Income / Expense)
/// - Category filter (single-select bottom sheet)
/// - Date range filter
/// - Text search across reference, party, description, notes
class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TransactionProvider>();
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

  Future<void> _pickDateRange() async {
    final provider = context.read<TransactionProvider>();
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: provider.hasDateFilter && provider.startDate != null
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

  void _navigateToDetails(TransactionModel t) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionDetailsScreen(transactionId: t.id),
      ),
    );
  }

  Future<void> _navigateToCreate() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _deleteTransaction(TransactionModel t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete "${t.category.label}" '
          'of ৳${t.amount.toStringAsFixed(2)}?',
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
      final provider = context.read<TransactionProvider>();
      try {
        await provider.deleteTransaction(t.id);
        if (!mounted) return;
        _showSnackBar('Transaction deleted', AppColors.success);
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('Failed: $e', AppColors.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Summary header
          Consumer<TransactionProvider>(
            builder: (context, provider, _) {
              return _buildSummaryHeader(provider);
            },
          ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                context.read<TransactionProvider>().setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Search reference, party, or notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<TransactionProvider>().setSearchQuery(
                            '',
                          );
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
          // Filter chips
          Consumer<TransactionProvider>(
            builder: (context, provider, _) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
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
                          ? () => provider.clearDateFilter()
                          : null,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: provider.hasCategoryFilter
                          ? 'Cat: ${provider.categoryFilter!.shortLabel}'
                          : 'Category',
                      icon: Icons.category_outlined,
                      isActive: provider.hasCategoryFilter,
                      onTap: () => _showCategorySheet(provider),
                      onClear: provider.hasCategoryFilter
                          ? () => provider.setCategoryFilter(null)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    if (provider.hasTypeFilter ||
                        provider.hasDateFilter ||
                        provider.hasCategoryFilter ||
                        provider.searchQuery.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          provider.clearFilters();
                        },
                        icon: const Icon(
                          Icons.filter_alt_off_outlined,
                          size: 18,
                        ),
                        label: const Text('Clear'),
                      ),
                  ],
                ),
              );
            },
          ),
          // Type toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Consumer<TransactionProvider>(
              builder: (context, provider, _) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildTypeSegment(
                        label: 'All',
                        icon: Icons.all_inclusive,
                        isActive: provider.typeFilter == null,
                        onTap: () => provider.setTypeFilter(null),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTypeSegment(
                        label: 'Income',
                        icon: Icons.trending_up,
                        isActive: provider.typeFilter == TransactionType.income,
                        color: AppColors.success,
                        onTap: () =>
                            provider.setTypeFilter(TransactionType.income),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTypeSegment(
                        label: 'Expense',
                        icon: Icons.trending_down,
                        isActive:
                            provider.typeFilter == TransactionType.expense,
                        color: AppColors.error,
                        onTap: () =>
                            provider.setTypeFilter(TransactionType.expense),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // List
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.transactions.isEmpty) {
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
                final items = provider.filteredTransactions;
                if (items.isEmpty) {
                  return _buildEmptyState(provider);
                }
                return RefreshIndicator(
                  onRefresh: () async => provider.startListening(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96, top: 4),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final t = items[i];
                      return TransactionCard(
                        transaction: t,
                        onTap: () => _navigateToDetails(t),
                        onLongPress: () => _deleteTransaction(t),
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
        label: const Text('New Transaction'),
      ),
    );
  }

  Widget _buildSummaryHeader(TransactionProvider provider) {
    final income = provider.totalIncome;
    final expense = provider.totalExpense;
    final net = provider.netCashFlow;
    final netColor = net >= 0 ? AppColors.success : AppColors.error;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Net Cash Flow',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${net >= 0 ? '+' : '-'} ৳${net.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: netColor == AppColors.error ? Colors.white : Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  label: 'Income',
                  value: '৳${income.toStringAsFixed(2)}',
                  icon: Icons.trending_up,
                  iconColor: Colors.greenAccent,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _summaryItem(
                  label: 'Expense',
                  value: '৳${expense.toStringAsFixed(2)}',
                  icon: Icons.trending_down,
                  iconColor: Colors.redAccent,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _summaryItem(
                  label: 'Count',
                  value: '${provider.filteredCount}',
                  icon: Icons.receipt_long_outlined,
                  iconColor: Colors.amberAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildTypeSegment({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? AppColors.primary;
    return Material(
      color: isActive ? activeColor.withValues(alpha: 0.12) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? activeColor : AppColors.divider,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? activeColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? activeColor : AppColors.textSecondary,
                ),
              ),
            ],
          ),
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
    final color = isActive ? AppColors.primary : AppColors.textSecondary;
    final bg = isActive
        ? AppColors.primary.withValues(alpha: 0.08)
        : Colors.white;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.fromLTRB(12, 8, onClear != null ? 4 : 12, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
              if (onClear != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 14, color: color),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(TransactionProvider provider) {
    final hasFilters =
        provider.hasDateFilter ||
        provider.hasTypeFilter ||
        provider.hasCategoryFilter ||
        provider.searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters
                  ? Icons.search_off
                  : Icons.account_balance_wallet_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No matching transactions' : 'No transactions yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your filters or search query'
                  : 'Tap the button below to record your first transaction',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (hasFilters)
              OutlinedButton.icon(
                onPressed: provider.clearFilters,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Clear Filters'),
              )
            else
              ElevatedButton.icon(
                onPressed: _navigateToCreate,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Transaction'),
              ),
          ],
        ),
      ),
    );
  }

  void _showCategorySheet(TransactionProvider provider) {
    final selectedType = provider.typeFilter;
    final incomeCategories = TransactionCategory.values
        .where((c) => c.isIncome)
        .toList();
    final expenseCategories = TransactionCategory.values
        .where((c) => !c.isIncome)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Filter by Category',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (selectedType != TransactionType.expense) ...[
                        _categorySectionHeader(
                          context: ctx,
                          label: 'Income',
                          color: AppColors.success,
                          icon: Icons.trending_up,
                        ),
                        ...incomeCategories.map((cat) {
                          final isSelected = provider.categoryFilter == cat;
                          return _categoryTile(
                            context: ctx,
                            label: cat.label,
                            iconName: cat.iconName,
                            isSelected: isSelected,
                            color: AppColors.success,
                            onTap: () {
                              provider.setCategoryFilter(cat);
                              Navigator.pop(ctx);
                            },
                          );
                        }),
                      ],
                      if (selectedType != TransactionType.income) ...[
                        _categorySectionHeader(
                          context: ctx,
                          label: 'Expense',
                          color: AppColors.error,
                          icon: Icons.trending_down,
                        ),
                        ...expenseCategories.map((cat) {
                          final isSelected = provider.categoryFilter == cat;
                          return _categoryTile(
                            context: ctx,
                            label: cat.label,
                            iconName: cat.iconName,
                            isSelected: isSelected,
                            color: AppColors.error,
                            onTap: () {
                              provider.setCategoryFilter(cat);
                              Navigator.pop(ctx);
                            },
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _categorySectionHeader({
    required BuildContext context,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: AppColors.background,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryTile({
    required BuildContext context,
    required String label,
    required String iconName,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(_iconFromName(iconName), color: color, size: 16),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? color : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: color) : null,
      onTap: onTap,
    );
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'point_of_sale':
        return const IconData(0xe54d, fontFamily: 'MaterialIcons');
      case 'attach_money':
        return const IconData(0xe227, fontFamily: 'MaterialIcons');
      case 'account_balance':
        return const IconData(0xe188, fontFamily: 'MaterialIcons');
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
        return const IconData(0xe9a5, fontFamily: 'MaterialIcons');
      case 'build':
        return const IconData(0xe1b9, fontFamily: 'MaterialIcons');
      case 'receipt_long':
        return const IconData(0xefee, fontFamily: 'MaterialIcons');
      case 'person_remove':
        return const IconData(0xe7fc, fontFamily: 'MaterialIcons');
      case 'request_quote':
        return const IconData(0xf02f, fontFamily: 'MaterialIcons');
      case 'store':
        return const IconData(0xe8d1, fontFamily: 'MaterialIcons');
      case 'currency_exchange':
        return const IconData(0xf1a3, fontFamily: 'MaterialIcons');
      default:
        return Icons.circle_outlined;
    }
  }
}
