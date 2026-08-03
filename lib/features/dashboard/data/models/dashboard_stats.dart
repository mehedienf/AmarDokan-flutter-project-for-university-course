import 'package:amar_dokan/features/inventory/data/models/product_model.dart';
import 'package:amar_dokan/features/sales/data/models/sale_model.dart';

/// DashboardStats - daily aggregate snapshot for the dashboard screen.
///
/// All money/totals are in BDT. Holds both today's totals AND full-store
/// totals so the dashboard can show a small "store-wide" footer under the
/// "today" KPIs without recomputing in the widget layer.
class DashboardStats {
  // ──────────────────────── Today's snapshot ────────────────────────
  final double todaysRevenue;
  final double todaysProfit;
  final int todaysSalesCount;
  final int todaysItemsSold;
  final double todaysIncome;
  final double todaysExpense;

  // ──────────────────── Store-wide aggregated KPIs ────────────────────
  final double totalRevenue;
  final double totalProfit;
  final int totalProducts;
  final int totalStockUnits;
  final double totalStockValue;
  final double totalPotentialProfit;
  final int lowStockCount;
  final int outOfStockCount;
  final double outstandingReceivables;
  final int completedSalesCount;

  // ─────────────────────────── Lists ──────────────────────────────────
  /// Most recent sales, ordered by saleDate desc. Top N only.
  /// Consumer must use `sale.total`, `sale.totalItems`, `sale.totalProfit`,
  /// `sale.customerName`, `sale.displayPaymentMethod` etc.
  final List<SaleModel> recentSales;

  /// Low-stock (still > 0) products. Ordered by stock ascending.
  final List<ProductModel> lowStockProducts;

  // ─────────────────────────── Helpers ────────────────────────────────
  bool get hasAnyData =>
      todaysSalesCount > 0 ||
      totalProducts > 0 ||
      todaysRevenue > 0 ||
      totalRevenue > 0;

  bool get hasLowStockAlerts => lowStockCount > 0 || outOfStockCount > 0;

  const DashboardStats({
    required this.todaysRevenue,
    required this.todaysProfit,
    required this.todaysSalesCount,
    required this.todaysItemsSold,
    required this.todaysIncome,
    required this.todaysExpense,
    required this.totalRevenue,
    required this.totalProfit,
    required this.totalProducts,
    required this.totalStockUnits,
    required this.totalStockValue,
    required this.totalPotentialProfit,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.outstandingReceivables,
    required this.completedSalesCount,
    required this.recentSales,
    required this.lowStockProducts,
  });

  /// Empty placeholder used when there is no data yet (e.g., loading
  /// state, or newly created account).
  factory DashboardStats.empty() {
    return DashboardStats(
      todaysRevenue: 0,
      todaysProfit: 0,
      todaysSalesCount: 0,
      todaysItemsSold: 0,
      todaysIncome: 0,
      todaysExpense: 0,
      totalRevenue: 0,
      totalProfit: 0,
      totalProducts: 0,
      totalStockUnits: 0,
      totalStockValue: 0,
      totalPotentialProfit: 0,
      lowStockCount: 0,
      outOfStockCount: 0,
      outstandingReceivables: 0,
      completedSalesCount: 0,
      recentSales: const [],
      lowStockProducts: const [],
    );
  }

  /// Profit margin for today (0 if no revenue). Used as label/subtitle.
  double get todaysProfitMarginPercent {
    if (todaysRevenue <= 0) return 0;
    return (todaysProfit / todaysRevenue) * 100;
  }

  double get todaysNetCashFlow => todaysIncome - todaysExpense;
}
