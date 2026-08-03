import 'package:amar_dokan/features/accounting/data/models/transaction_model.dart';

import 'report_period.dart';

/// ReportSummary - immutable aggregate of all metrics across a date range.
///
/// Everything the report UI needs in a single object so the Provider can
/// recompute once and the UI can rebuild cheaply.
class ReportSummary {
  final ReportPeriod period;

  // ─── Sales ───────────────────────────────────────────────────────────────
  final double totalRevenue;
  final double totalDiscount;
  final double totalTax;
  final int totalSales;
  final int completedSales;
  final int cancelledSales;
  final double averageSaleValue;
  final int totalItemsSold;
  final double totalProfit; // profit tracked per sale-item at sale time
  final double outstandingReceivables; // unpaid + partial balances

  // ─── Purchases ───────────────────────────────────────────────────────────
  final double totalPurchaseAmount;
  final double totalPurchasePaid;
  final double outstandingPayables; // unpaid + partial balances
  final int totalPurchases;

  // ─── Transactions (other income/expense) ────────────────────────────────
  final double otherIncome;
  final double otherExpenses;
  final int incomeTransactionCount;
  final int expenseTransactionCount;

  // ─── Inventory snapshot (point-in-time, not range-filtered) ──────────────
  final int totalProducts;
  final int totalStockUnits;
  final double totalInventoryValue; // stock × purchasePrice
  final double totalInventoryPotentialProfit; // stock × (sell − cost)
  final int lowStockCount;
  final int outOfStockCount;

  // ─── Cash flow (derived) ────────────────────────────────────────────────
  final double totalCashIn; // revenue + otherIncome
  final double totalCashOut; // purchases paid + otherExpenses
  final double netCashFlow; // in − out

  // ─── Trends / breakdowns ─────────────────────────────────────────────────
  final List<DailyDataPoint> dailySalesTrend;
  final List<DailyDataPoint> dailyProfitTrend;
  final List<NamedValue> topProducts; // by revenue
  final List<NamedValue> topCustomers; // by revenue
  final List<NamedValue> paymentMethodBreakdown; // by count
  final Map<TransactionCategory, double> expensesByCategory;
  final List<NamedValue> topCategoriesByProfit; // inventory category profit

  const ReportSummary({
    required this.period,
    required this.totalRevenue,
    required this.totalDiscount,
    required this.totalTax,
    required this.totalSales,
    required this.completedSales,
    required this.cancelledSales,
    required this.averageSaleValue,
    required this.totalItemsSold,
    required this.totalProfit,
    required this.outstandingReceivables,
    required this.totalPurchaseAmount,
    required this.totalPurchasePaid,
    required this.outstandingPayables,
    required this.totalPurchases,
    required this.otherIncome,
    required this.otherExpenses,
    required this.incomeTransactionCount,
    required this.expenseTransactionCount,
    required this.totalProducts,
    required this.totalStockUnits,
    required this.totalInventoryValue,
    required this.totalInventoryPotentialProfit,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalCashIn,
    required this.totalCashOut,
    required this.netCashFlow,
    required this.dailySalesTrend,
    required this.dailyProfitTrend,
    required this.topProducts,
    required this.topCustomers,
    required this.paymentMethodBreakdown,
    required this.expensesByCategory,
    required this.topCategoriesByProfit,
  });

  /// Empty summary used as initial state.
  factory ReportSummary.empty(ReportPeriod period) {
    return ReportSummary(
      period: period,
      totalRevenue: 0,
      totalDiscount: 0,
      totalTax: 0,
      totalSales: 0,
      completedSales: 0,
      cancelledSales: 0,
      averageSaleValue: 0,
      totalItemsSold: 0,
      totalProfit: 0,
      outstandingReceivables: 0,
      totalPurchaseAmount: 0,
      totalPurchasePaid: 0,
      outstandingPayables: 0,
      totalPurchases: 0,
      otherIncome: 0,
      otherExpenses: 0,
      incomeTransactionCount: 0,
      expenseTransactionCount: 0,
      totalProducts: 0,
      totalStockUnits: 0,
      totalInventoryValue: 0,
      totalInventoryPotentialProfit: 0,
      lowStockCount: 0,
      outOfStockCount: 0,
      totalCashIn: 0,
      totalCashOut: 0,
      netCashFlow: 0,
      dailySalesTrend: const [],
      dailyProfitTrend: const [],
      topProducts: const [],
      topCustomers: const [],
      paymentMethodBreakdown: const [],
      expensesByCategory: const {},
      topCategoriesByProfit: const [],
    );
  }

  // ─── Derived / convenience getters ──────────────────────────────────────

  /// Profit margin as a percentage (0–100). Returns 0 when revenue is 0.
  double get profitMargin =>
      totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;

  /// Sales-to-purchase ratio (efficiency indicator).
  double get salesToPurchaseRatio =>
      totalPurchaseAmount > 0 ? totalRevenue / totalPurchaseAmount : 0;

  bool get hasAnyData =>
      totalSales > 0 ||
      totalPurchases > 0 ||
      incomeTransactionCount > 0 ||
      expenseTransactionCount > 0 ||
      totalProducts > 0;
}

/// Single data point on a time-series chart.
class DailyDataPoint {
  final DateTime date;
  final double value;

  const DailyDataPoint({required this.date, required this.value});

  String get label {
    // Short label like "Mon", "5", "5/12" — chosen by date distance
    final now = DateTime.now();
    final daysDiff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays
        .abs();
    if (daysDiff < 7) {
      const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return names[date.weekday - 1];
    }
    if (daysDiff < 90) {
      return '${date.day}/${date.month}';
    }
    return '${date.month}/${date.year % 100}';
  }

  String get fullLabel =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

/// A name → value pair used for rankings.
class NamedValue {
  final String name;
  final double value;
  final String? subtitle;
  final String? id;

  const NamedValue({
    required this.name,
    required this.value,
    this.subtitle,
    this.id,
  });
}