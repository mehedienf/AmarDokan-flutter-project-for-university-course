// ignore_for_file: use_build_context_synchronously

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/features/dashboard/data/models/dashboard_stats.dart';
import 'package:amar_dokan/features/dashboard/data/services/dashboard_service.dart';
import 'package:amar_dokan/features/inventory/providers/inventory_provider.dart';
import 'package:amar_dokan/features/sales/providers/sale_provider.dart';
import 'package:amar_dokan/features/purchase/providers/purchase_provider.dart';
import 'package:amar_dokan/features/accounting/providers/transaction_provider.dart';

/// DashboardProvider - state holder for the home dashboard screen.
///
/// Holds the latest [DashboardStats] snapshot and a flag for whether a
/// recompute is in flight. The screen calls [recompute] from `build()` (or
/// on pull-to-refresh) and the provider reads from each source provider
/// synchronously, computes the aggregate, then notifies listeners.
class DashboardProvider extends ChangeNotifier {
  DashboardStats _stats = DashboardStats.empty();
  bool _isComputing = false;
  final DashboardService _service;

  DashboardProvider({DashboardService? service})
      : _service = service ?? const DashboardService();

  DashboardStats get stats => _stats;
  bool get isComputing => _isComputing;

  /// Recompute the snapshot from all source providers.
  ///
  /// Returns a [Future] so callers (e.g. `RefreshIndicator`) can await
  /// completion. Yields one frame before running so a spinner can paint.
  Future<void> recompute(BuildContext context) async {
    _isComputing = true;
    notifyListeners();

    await Future<void>.delayed(Duration.zero);

    final sales = context.read<SaleProvider>();
    final purchases = context.read<PurchaseProvider>();
    final transactions = context.read<TransactionProvider>();
    final products = context.read<InventoryProvider>();

    _stats = _service.compute(
      sales: sales,
      purchases: purchases,
      transactions: transactions,
      products: products,
    );

    _isComputing = false;
    notifyListeners();
  }
}