import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';
import 'package:amar_dokan/core/providers/navigation_provider.dart';
import 'package:amar_dokan/features/dashboard/data/models/dashboard_stats.dart';
import 'package:amar_dokan/features/dashboard/presentation/widgets/dashboard_section_title.dart';
import 'package:amar_dokan/features/dashboard/presentation/widgets/dashboard_stat_card.dart';
import 'package:amar_dokan/features/dashboard/presentation/widgets/low_stock_list.dart';
import 'package:amar_dokan/features/dashboard/presentation/widgets/quick_actions.dart';
import 'package:amar_dokan/features/dashboard/presentation/widgets/recent_sales_list.dart';
import 'package:amar_dokan/features/dashboard/providers/dashboard_provider.dart';
import 'package:amar_dokan/features/inventory/providers/inventory_provider.dart';
import 'package:amar_dokan/features/sales/providers/sale_provider.dart';
import 'package:amar_dokan/features/purchase/providers/purchase_provider.dart';
import 'package:amar_dokan/features/accounting/providers/transaction_provider.dart';

/// DashboardScreen - the home tab. Aggregates today's KPIs + store-wide
/// health + recent activity into one scrollable view.
///
/// - Pull-to-refresh triggers [DashboardProvider.recompute]
/// - Quick action tiles jump to common flows
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    // The four source providers normally start their Firestore stream
    // listeners from inside their respective screen. The dashboard is the
    // first screen the user sees — kick off listening so the data is ready
    // when they arrive. Safe to call repeatedly; each provider guards
    // against double-subscription.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SaleProvider>().startListening();
      context.read<InventoryProvider>().startListening();
      context.read<PurchaseProvider>().startListening();
      context.read<TransactionProvider>().startListening();

      // First compute.
      context.read<DashboardProvider>().recompute(context);
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    await context.read<DashboardProvider>().recompute(context);
  }

  void _goToTab(int index) {
    context.read<NavigationProvider>().setCurrentIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final stats = provider.stats;
        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _GreetingHeader(),
              const SizedBox(height: 16),
              _TodaysSnapshot(stats: stats),
              const SizedBox(height: 24),
              const DashboardSectionTitle(
                title: 'Quick Actions',
                icon: Icons.bolt,
              ),
              QuickActions(actions: _buildActions()),
              const SizedBox(height: 24),
              DashboardSectionTitle(
                title: 'Store Health',
                icon: Icons.monitor_heart_outlined,
                actionLabel: 'Inventory',
                onAction: () => _goToTab(1),
              ),
              _StoreHealth(stats: stats),
              const SizedBox(height: 24),
              DashboardSectionTitle(
                title: 'Recent Sales',
                icon: Icons.receipt_long,
                actionLabel: 'View all',
                onAction: () => _goToTab(2),
              ),
              RecentSalesList(sales: stats.recentSales),
              if (stats.hasLowStockAlerts) ...[
                const SizedBox(height: 24),
                DashboardSectionTitle(
                  title: 'Low Stock Alerts',
                  icon: Icons.warning_amber,
                  actionLabel: 'View all',
                  onAction: () => _goToTab(1),
                ),
                LowStockList(products: stats.lowStockProducts),
              ],
              const SizedBox(height: 16),
              _ReportsFooter(stats: stats),
            ],
          ),
        );
      },
    );
  }

  List<QuickAction> _buildActions() {
    return [
      QuickAction(
        label: 'New Sale',
        icon: Icons.point_of_sale,
        color: AppColors.primary,
        onTap: () => _goToTab(2),
      ),
      QuickAction(
        label: 'Add Stock',
        icon: Icons.add_box,
        color: AppColors.secondary,
        onTap: () => _goToTab(1),
      ),
      QuickAction(
        label: 'Reports',
        icon: Icons.bar_chart,
        color: AppColors.info,
        onTap: () => _goToTab(3),
      ),
      QuickAction(
        label: 'Refresh Data',
        icon: Icons.refresh,
        color: AppColors.success,
        onTap: _refresh,
      ),
    ];
  }
}

// ============================================================================
//  Section widgets
// ============================================================================

class _GreetingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'শুভ সকাল'
        : hour < 17
            ? 'শুভ দুপুর'
                : 'শুভ সন্ধ্যা';
    final english = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final todayString = DateFormat('EEEE, d MMM yyyy').format(now);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.storefront,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$english • $todayString',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodaysSnapshot extends StatelessWidget {
  final DashboardStats stats;

  const _TodaysSnapshot({required this.stats});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      symbol: '৳',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    final marginPct = stats.todaysProfitMarginPercent;
    final marginLabel = stats.todaysRevenue <= 0
        ? 'No sales today'
        : '${marginPct.toStringAsFixed(1)}% margin';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionTitle(
          title: "Today's Snapshot",
          icon: Icons.today,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DashboardStatCard(
                title: 'Revenue',
                value: currency.format(stats.todaysRevenue),
                icon: Icons.payments,
                color: AppColors.salesCard,
                sublabel: stats.todaysSalesCount == 1
                    ? '1 sale'
                    : '${stats.todaysSalesCount} sales',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardStatCard(
                title: 'Profit',
                value: currency.format(stats.todaysProfit),
                icon: Icons.trending_up,
                color: AppColors.profitCard,
                sublabel: marginLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DashboardStatCard(
                title: 'Items Sold',
                value: '${stats.todaysItemsSold}',
                icon: Icons.inventory_2_outlined,
                color: AppColors.stockCard,
                sublabel: 'Units',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardStatCard(
                title: 'Net Cash',
                value: currency.format(stats.todaysNetCashFlow),
                icon: stats.todaysNetCashFlow >= 0
                    ? Icons.account_balance_wallet
                    : Icons.account_balance_wallet_outlined,
                color: stats.todaysNetCashFlow >= 0
                    ? AppColors.success
                    : AppColors.error,
                sublabel: stats.todaysNetCashFlow >= 0
                    ? 'Income − expense'
                    : 'Cash out today',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StoreHealth extends StatelessWidget {
  final DashboardStats stats;

  const _StoreHealth({required this.stats});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      symbol: '৳',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DashboardStatCard(
                title: 'Products',
                value: '${stats.totalProducts}',
                icon: Icons.inventory,
                color: AppColors.primary,
                sublabel: '${stats.totalStockUnits} units in stock',
                onTap: () =>
                    context.read<NavigationProvider>().setCurrentIndex(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardStatCard(
                title: 'Stock Value',
                value: currency.format(stats.totalStockValue),
                icon: Icons.account_balance,
                color: AppColors.info,
                sublabel:
                    'Profit potential ${currency.format(stats.totalPotentialProfit)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DashboardStatCard(
                title: 'Low Stock',
                value: '${stats.lowStockCount}',
                icon: Icons.warning_amber,
                color: AppColors.warning,
                sublabel: 'Need attention',
                onTap: () =>
                    context.read<NavigationProvider>().setCurrentIndex(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardStatCard(
                title: 'Out of Stock',
                value: '${stats.outOfStockCount}',
                icon: Icons.remove_circle_outline,
                color: AppColors.lowStockCard,
                sublabel: 'Restock now',
                onTap: () =>
                    context.read<NavigationProvider>().setCurrentIndex(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DashboardStatCard(
                title: 'Total Sales',
                value: currency.format(stats.totalRevenue),
                icon: Icons.analytics,
                color: AppColors.success,
                sublabel: '${stats.completedSalesCount} completed',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardStatCard(
                title: 'Receivables',
                value: currency.format(stats.outstandingReceivables),
                icon: Icons.account_balance_wallet,
                color: AppColors.secondary,
                sublabel: 'Owed to you',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Footer card linking to the Reports tab and showing the cutoff date.
class _ReportsFooter extends StatelessWidget {
  final DashboardStats stats;

  const _ReportsFooter({required this.stats});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      symbol: '৳',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    final noData = !stats.hasAnyData;

    return Card(
      color: AppColors.primary,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.read<NavigationProvider>().setCurrentIndex(3),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detailed Reports',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      noData
                          ? 'Track sales, profit, and inventory trends'
                          : 'Lifetime revenue ${currency.format(stats.totalRevenue)} • '
                              'Profit ${currency.format(stats.totalProfit)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}