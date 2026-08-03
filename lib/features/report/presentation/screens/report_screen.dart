import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';
import 'package:amar_dokan/features/accounting/providers/transaction_provider.dart';
import 'package:amar_dokan/features/inventory/providers/inventory_provider.dart';
import 'package:amar_dokan/features/purchase/providers/purchase_provider.dart';
import 'package:amar_dokan/features/sales/providers/sale_provider.dart';
import 'package:amar_dokan/features/report/data/models/report_period.dart';
import 'package:amar_dokan/features/report/presentation/widgets/inventory_tab.dart';
import 'package:amar_dokan/features/report/presentation/widgets/overview_tab.dart';
import 'package:amar_dokan/features/report/presentation/widgets/period_selector.dart';
import 'package:amar_dokan/features/report/presentation/widgets/profit_tab.dart';
import 'package:amar_dokan/features/report/presentation/widgets/sales_tab.dart';
import 'package:amar_dokan/features/report/providers/report_provider.dart';

/// ReportScreen - top-level analytics view.
///
/// Holds the TabController, exposes the period selector in the AppBar bottom,
/// and uses IndexedStack to preserve each tab's scroll state. Pull-to-refresh
/// re-runs aggregation against the latest source data.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const _tabs = <String>[
    'Overview',
    'Sales',
    'Inventory',
    'Profit',
  ];

  /// Fingerprint of the source-provider data the last time we triggered a
  /// recompute. Used by [_maybeRecompute] to avoid re-running the aggregation
  /// when only `ReportProvider` itself notified (which would otherwise form
  /// an infinite build/recompute loop).
  String _lastSourceFingerprint = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    // First compute after the first frame so source providers are mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _lastSourceFingerprint = _captureSourceFingerprint();
        context.read<ReportProvider>().recompute(context);
      }
    });
  }

  /// Capture a stable fingerprint of the four source-provider lists. We use
  /// `length` because the actual records are deep-equality costly and we only
  /// care about "did anything change since last compute".
  String _captureSourceFingerprint() {
    final sales = context.read<SaleProvider>().sales.length;
    final purchases = context.read<PurchaseProvider>().purchases.length;
    final txns = context.read<TransactionProvider>().transactions.length;
    final products = context.read<InventoryProvider>().products.length;
    return '$sales|$purchases|$txns|$products';
  }

  /// Side-effect called from `build`. Schedules a recompute for the next
  /// frame if any source-provider list grew/changed since the last compute.
  void _maybeRecompute() {
    final fingerprint = _captureSourceFingerprint();
    if (fingerprint == _lastSourceFingerprint) return;
    _lastSourceFingerprint = fingerprint;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReportProvider>().recompute(context);
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<ReportProvider>().recompute(context);
  }

  void _onPeriodChanged(ReportPeriodType type) {
    context.read<ReportProvider>().setPeriod(type);
    _lastSourceFingerprint = ''; // force recompute
    context.read<ReportProvider>().recompute(context);
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (picked != null && mounted) {
      context.read<ReportProvider>().setCustomPeriod(
            picked.start,
            picked.end,
            label:
                '${_shortDate(picked.start)} → ${_shortDate(picked.end)}',
          );
      _lastSourceFingerprint = ''; // force recompute
      await context.read<ReportProvider>().recompute(context);
    }
  }

  String _shortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    // The outer `MainApp` already provides the AppBar (showing "Report" as
    // the page title), so this screen returns its body only. The period
    // chip row sits at the top of the body, and the tab strip at the bottom.
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        // Watch the four source providers so the screen rebuilds when any
        // of them emits a new snapshot (e.g. a sale is added while the
        // Report tab is open). The side-effect recompute is scheduled via
        // addPostFrameCallback inside `_maybeRecompute`, which guards
        // against redundant work when only `ReportProvider` itself
        // notified listeners.
        context.watch<SaleProvider>();
        context.watch<PurchaseProvider>();
        context.watch<TransactionProvider>();
        context.watch<InventoryProvider>();
        _maybeRecompute();

        return Column(
          children: [
            // Period chip strip — sits directly under the outer AppBar so
            // there's no duplicate title bar. Compact padding keeps the
            // page header slim.
            Container(
              // color: AppColors.primary,
              padding: const EdgeInsets.only(bottom: 4),
              child: PeriodSelector(
                selectedType: provider.period.type,
                onChanged: _onPeriodChanged,
                onCustomRangeTap: _pickCustomRange,
              ),
            ),
            Expanded(
              child: () {
                if (provider.isComputing && !provider.summary.hasAnyData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppColors.primary,
                  child: IndexedStack(
                    index: _tabController.index,
                    children: [
                      OverviewTab(summary: provider.summary),
                      SalesTab(summary: provider.summary),
                      InventoryTab(summary: provider.summary),
                      ProfitTab(summary: provider.summary),
                    ],
                  ),
                );
              }(),
            ),
            Material(
              color: AppColors.primary,
              child: SafeArea(
                top: false,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: [
                    for (final t in _tabs) Tab(text: t),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}