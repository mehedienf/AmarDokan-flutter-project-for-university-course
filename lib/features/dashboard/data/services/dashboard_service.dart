import 'package:amar_dokan/features/dashboard/data/models/dashboard_stats.dart';
import 'package:amar_dokan/features/inventory/data/models/product_model.dart';
import 'package:amar_dokan/features/inventory/providers/inventory_provider.dart';
import 'package:amar_dokan/features/sales/data/models/sale_model.dart';
import 'package:amar_dokan/features/sales/providers/sale_provider.dart';
import 'package:amar_dokan/features/purchase/providers/purchase_provider.dart';
import 'package:amar_dokan/features/accounting/providers/transaction_provider.dart';

/// DashboardService - pure aggregation of today's + store-wide KPIs.
///
/// Stateless: takes a value-object [DashboardStats] back. Pulls from the
/// existing source providers (no extra Firestore reads) so the dashboard
/// stays in sync with Inventory/Sales/Purchase/Accounting screens.
class DashboardService {
  const DashboardService();

  /// Number of recent sales to surface on the dashboard.
  static const int recentSalesLimit = 5;

  /// Number of low-stock products to surface on the dashboard.
  static const int lowStockProductsLimit = 5;

  /// Build a fresh [DashboardStats] snapshot from the four source providers.
  ///
  /// All aggregation is synchronous — we already hold the data in memory.
  DashboardStats compute({
    required SaleProvider sales,
    required PurchaseProvider purchases,
    required TransactionProvider transactions,
    required InventoryProvider products,
  }) {
    final allSales = sales.sales;
    final todaysSales = _filterToday(allSales);

    // Revenue / profit / items / count from sales.
    final todaysRevenue = todaysSales.fold<double>(
      0,
      (sum, s) => sum + s.total,
    );
    final todaysProfit = todaysSales.fold<double>(
      0,
      (sum, s) => sum + s.totalProfit,
    );
    final todaysItemsSold = todaysSales.fold<int>(
      0,
      (sum, s) => sum + s.totalItems,
    );

    // Today's accounting snapshot.
    final todaysIncome = transactions.todaysIncome;
    final todaysExpense = transactions.todaysExpense;

    // Recent sales — newest first, top N.
    final recentSales = _topRecent(allSales, recentSalesLimit);

    // Low-stock products — sorted by stock ascending (lowest first), then
    // out-of-stock, then by name. Top N only.
    final lowStockProducts = _topLowStock(
      products.lowStockProducts,
      lowStockProductsLimit,
    );

    return DashboardStats(
      todaysRevenue: todaysRevenue,
      todaysProfit: todaysProfit,
      todaysSalesCount: todaysSales.length,
      todaysItemsSold: todaysItemsSold,
      todaysIncome: todaysIncome,
      todaysExpense: todaysExpense,
      totalRevenue: sales.totalRevenue,
      totalProfit: sales.totalProfit,
      totalProducts: products.totalProducts,
      totalStockUnits: products.totalStock,
      totalStockValue: products.totalStockValue,
      totalPotentialProfit: products.totalPotentialProfit,
      lowStockCount: products.lowStockCount,
      outOfStockCount: products.outOfStockCount,
      outstandingReceivables: sales.totalPendingAmount,
      completedSalesCount: sales.completedSalesCount,
      recentSales: recentSales,
      lowStockProducts: lowStockProducts,
    );
  }

  // ─────────────────────────── Private helpers ────────────────────────────

  /// Sales that happened today (between local midnight and end-of-day).
  static List<SaleModel> _filterToday(List<SaleModel> all) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return all
        .where((s) {
          final date = s.saleDate ?? s.createdAt;
          return !date.isBefore(start) && date.isBefore(end);
        })
        .toList();
  }

  static List<SaleModel> _topRecent(List<SaleModel> all, int limit) {
    final sorted = [...all]
      ..sort((a, b) {
        final aDate = a.saleDate ?? a.createdAt;
        final bDate = b.saleDate ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
    if (sorted.length <= limit) return sorted;
    return sorted.sublist(0, limit);
  }

  static List<ProductModel> _topLowStock(
    List<ProductModel> lowStock,
    int limit,
  ) {
    final sorted = [...lowStock]
      ..sort((a, b) {
        // Out-of-stock (stock == 0) first, then by stock ascending.
        if (a.isOutOfStock && !b.isOutOfStock) return -1;
        if (!a.isOutOfStock && b.isOutOfStock) return 1;
        if (a.stock != b.stock) return a.stock.compareTo(b.stock);
        return a.name.compareTo(b.name);
      });
    if (sorted.length <= limit) return sorted;
    return sorted.sublist(0, limit);
  }
}
