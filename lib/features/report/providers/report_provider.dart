import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/features/accounting/providers/transaction_provider.dart';
import 'package:amar_dokan/features/inventory/providers/inventory_provider.dart';
import 'package:amar_dokan/features/purchase/providers/purchase_provider.dart';
import 'package:amar_dokan/features/sales/providers/sale_provider.dart';

import '../data/models/report_period.dart';
import '../data/models/report_summary.dart';
import '../data/services/report_service.dart';

/// ReportProvider - holds the active [ReportPeriod] and the computed
/// [ReportSummary] for the Report feature.
///
/// The provider is intentionally **stateless** about source data — it pulls
/// sales/purchases/transactions/products from their respective providers at
/// recompute time, which means a single `recompute()` call is enough to
/// refresh everything.
///
/// Source providers are injected through [BuildContext] at construction in
/// `main.dart` so the Provider can read from them without an explicit
/// dependency wiring.
class ReportProvider extends ChangeNotifier {
  final ReportService _service;

  ReportPeriod _period;
  ReportSummary _summary;
  bool _isComputing = false;

  ReportProvider({
    ReportService? service,
    ReportPeriod? initialPeriod,
  })  : _service = service ?? const ReportService(),
        _period = initialPeriod ?? ReportPeriod.fromType(ReportPeriodType.thisMonth),
        _summary = ReportSummary.empty(
          initialPeriod ?? ReportPeriod.fromType(ReportPeriodType.thisMonth),
        );

  // ─── Public getters ─────────────────────────────────────────────────────

  ReportPeriod get period => _period;
  ReportSummary get summary => _summary;
  bool get isComputing => _isComputing;

  /// Switch the active period to a preset (today, this week, etc).
  void setPeriod(ReportPeriodType type, {DateTime? now}) {
    _period = ReportPeriod.fromType(type, now: now);
    notifyListeners();
  }

  /// Switch to a custom date range (e.g. user picked from a date picker).
  void setCustomPeriod(DateTime start, DateTime end, {String? label}) {
    _period = ReportPeriod(
      type: ReportPeriodType.custom,
      label: label ?? 'Custom Range',
      startDate: DateTime(start.year, start.month, start.day),
      endDate: DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
    notifyListeners();
  }

  /// Recompute the summary by pulling fresh data from each source provider.
  ///
  /// Returns a Future so `RefreshIndicator` callers can await completion.
  /// The actual computation is synchronous, but the yield pattern lets the
  /// spinner show during the frame.
  Future<void> recompute(BuildContext context) async {
    _isComputing = true;
    notifyListeners();

    // Yield one frame so the progress indicator can render before the
    // synchronous aggregation finishes.
    await Future<void>.delayed(Duration.zero);

    final sales = context.read<SaleProvider>().sales;
    final purchases = context.read<PurchaseProvider>().purchases;
    final transactions = context.read<TransactionProvider>().transactions;
    final products = context.read<InventoryProvider>().products;

    _summary = _service.compute(
      period: _period,
      sales: sales,
      purchases: purchases,
      transactions: transactions,
      products: products,
    );

    _isComputing = false;
    notifyListeners();
  }

  /// Convenience: recompute using a fresh, internally-created service call.
  /// Useful for tests or when no BuildContext is available.
  void recomputeWith({
    required List sales,
    required List purchases,
    required List transactions,
    required List products,
  }) {
    _isComputing = true;
    notifyListeners();
    _summary = _service.compute(
      period: _period,
      sales: sales.cast(),
      purchases: purchases.cast(),
      transactions: transactions.cast(),
      products: products.cast(),
    );
    _isComputing = false;
    notifyListeners();
  }
}