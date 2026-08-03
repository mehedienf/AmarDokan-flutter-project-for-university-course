import 'package:amar_dokan/features/accounting/data/models/transaction_model.dart';
import 'package:amar_dokan/features/inventory/data/models/product_model.dart';
import 'package:amar_dokan/features/purchase/data/models/purchase_model.dart';
import 'package:amar_dokan/features/sales/data/models/sale_model.dart';

import '../models/report_period.dart';
import '../models/report_summary.dart';

/// ReportService - pure aggregation logic for the Report feature.
///
/// Stateless. All input lists are passed in (already loaded by their respective
/// providers); service just filters by period and computes aggregates. This
/// keeps the UI rebuild logic trivial — the Provider just calls
/// `compute(period, ...all lists)` whenever anything changes.
class ReportService {
  const ReportService();

  /// Build a [ReportSummary] covering the given [period].
  ///
  /// Each input list may be filtered or sliced — service applies the period
  /// filter to sales, purchases and transactions, and treats products as a
  /// point-in-time snapshot (not range filtered).
  ReportSummary compute({
    required ReportPeriod period,
    required List<SaleModel> sales,
    required List<PurchaseModel> purchases,
    required List<TransactionModel> transactions,
    required List<ProductModel> products,
  }) {
    // ─── Sales within period ───────────────────────────────────────────────
    final periodSales =
        sales.where((s) => period.contains(s.saleDate ?? s.createdAt)).toList();
    final completedSales = periodSales
        .where((s) => s.status == 'completed')
        .toList(growable: false);
    final cancelledSales =
        periodSales.where((s) => s.status == 'cancelled').length;

    double totalRevenue = 0;
    double totalDiscount = 0;
    double totalTax = 0;
    int totalItemsSold = 0;
    double totalProfit = 0;
    double outstandingReceivables = 0;

    for (final s in completedSales) {
      totalRevenue += s.total;
      totalDiscount += s.itemDiscount + s.extraDiscount;
      totalTax += s.tax;
      totalItemsSold += s.totalItems;
      totalProfit += s.totalProfit;
      outstandingReceivables += s.balance;
    }

    final avgSale =
        completedSales.isEmpty ? 0.0 : totalRevenue / completedSales.length;

    // ─── Purchases within period ───────────────────────────────────────────
    final periodPurchases = purchases
        .where((p) => period.contains(p.purchaseDate ?? p.createdAt))
        .toList();
    double totalPurchaseAmount = 0;
    double totalPurchasePaid = 0;
    double outstandingPayables = 0;
    for (final p in periodPurchases) {
      totalPurchaseAmount += p.total;
      totalPurchasePaid += p.paidAmount;
      outstandingPayables += p.balance;
    }

    // ─── Other transactions within period ──────────────────────────────────
    final periodTxns = transactions
        .where((t) => period.contains(t.transactionDate))
        .toList();
    double otherIncome = 0;
    double otherExpenses = 0;
    int incomeCount = 0;
    int expenseCount = 0;
    final expensesByCategory = <TransactionCategory, double>{};

    for (final t in periodTxns) {
      if (t.type == TransactionType.income) {
        otherIncome += t.amount;
        incomeCount++;
      } else {
        otherExpenses += t.amount;
        expenseCount++;
        expensesByCategory.update(
          t.category,
          (v) => v + t.amount,
          ifAbsent: () => t.amount,
        );
      }
    }

    // ─── Inventory snapshot ────────────────────────────────────────────────
    int totalStockUnits = 0;
    double totalInventoryValue = 0;
    double totalInventoryPotentialProfit = 0;
    int lowStockCount = 0;
    int outOfStockCount = 0;
    final categoryProfit = <String, double>{};

    for (final p in products) {
      totalStockUnits += p.stock;
      totalInventoryValue += p.totalStockValue;
      totalInventoryPotentialProfit += p.totalPotentialProfit;
      if (p.isOutOfStock) {
        outOfStockCount++;
      } else if (p.isLowStock) {
        lowStockCount++;
      }
      categoryProfit.update(
        p.category.displayName,
        (v) => v + p.totalPotentialProfit,
        ifAbsent: () => p.totalPotentialProfit,
      );
    }

    // ─── Cash flow (range-scoped) ──────────────────────────────────────────
    final totalCashIn = totalRevenue + otherIncome;
    final totalCashOut = totalPurchasePaid + otherExpenses;
    final netCashFlow = totalCashIn - totalCashOut;

    // ─── Trends: daily sales & profit ──────────────────────────────────────
    final dailySales = _bucketDailyBetween(
      completedSales,
      period.startDate,
      period.endDate,
      keyFn: (s) => s.saleDate ?? s.createdAt,
      valueFn: (s) => s.total,
    );
    final dailyProfit = _bucketDailyBetween(
      completedSales,
      period.startDate,
      period.endDate,
      keyFn: (s) => s.saleDate ?? s.createdAt,
      valueFn: (s) => s.totalProfit,
    );

    // ─── Top products (by revenue across the period) ──────────────────────
    final productRevenue = <String, _NamedAccum>{};
    for (final s in completedSales) {
      for (final item in s.items) {
        final existing = productRevenue[item.productName];
        if (existing == null) {
          productRevenue[item.productName] = _NamedAccum(
            name: item.productName,
            value: item.total,
            subtitle: '${item.quantity} sold',
            id: item.productId,
          );
        } else {
          existing.value += item.total;
          existing.subtitle = '${existing.subtitle} • ${item.quantity} sold';
        }
      }
    }
    final topProducts = productRevenue.values
        .map((n) => NamedValue(
              name: n.name,
              value: n.value,
              subtitle: n.subtitle,
              id: n.id,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // ─── Top customers (by revenue) ────────────────────────────────────────
    final customerRevenue = <String, _NamedAccum>{};
    for (final s in completedSales) {
      final key = (s.customerName != null && s.customerName!.trim().isNotEmpty)
          ? s.customerName!
          : 'Walk-in Customer';
      final existing = customerRevenue[key];
      if (existing == null) {
        customerRevenue[key] = _NamedAccum(
          name: key,
          value: s.total,
          subtitle: '1 order',
          id: s.customerId,
        );
      } else {
        existing.value += s.total;
        existing.subtitle =
            '${int.parse(existing.subtitle!.split(' ').first) + 1} orders';
      }
    }
    final topCustomers = customerRevenue.values
        .map((n) => NamedValue(
              name: n.name,
              value: n.value,
              subtitle: n.subtitle,
              id: n.id,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // ─── Payment method breakdown (by count) ──────────────────────────────
    final paymentCount = <String, int>{};
    for (final s in completedSales) {
      paymentCount.update(
        s.displayPaymentMethod,
        (v) => v + 1,
        ifAbsent: () => 1,
      );
    }
    final paymentMethodBreakdown = paymentCount.entries
        .map((e) => NamedValue(
              name: e.key,
              value: e.value.toDouble(),
              subtitle: '${e.value} ${e.value == 1 ? "sale" : "sales"}',
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // ─── Top inventory categories by potential profit ──────────────────────
    final topCategoriesByProfit = categoryProfit.entries
        .map((e) => NamedValue(name: e.key, value: e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ReportSummary(
      period: period,
      totalRevenue: totalRevenue,
      totalDiscount: totalDiscount,
      totalTax: totalTax,
      totalSales: periodSales.length,
      completedSales: completedSales.length,
      cancelledSales: cancelledSales,
      averageSaleValue: avgSale,
      totalItemsSold: totalItemsSold,
      totalProfit: totalProfit,
      outstandingReceivables: outstandingReceivables,
      totalPurchaseAmount: totalPurchaseAmount,
      totalPurchasePaid: totalPurchasePaid,
      outstandingPayables: outstandingPayables,
      totalPurchases: periodPurchases.length,
      otherIncome: otherIncome,
      otherExpenses: otherExpenses,
      incomeTransactionCount: incomeCount,
      expenseTransactionCount: expenseCount,
      totalProducts: products.length,
      totalStockUnits: totalStockUnits,
      totalInventoryValue: totalInventoryValue,
      totalInventoryPotentialProfit: totalInventoryPotentialProfit,
      lowStockCount: lowStockCount,
      outOfStockCount: outOfStockCount,
      totalCashIn: totalCashIn,
      totalCashOut: totalCashOut,
      netCashFlow: netCashFlow,
      dailySalesTrend: dailySales,
      dailyProfitTrend: dailyProfit,
      topProducts: topProducts.take(5).toList(),
      topCustomers: topCustomers.take(5).toList(),
      paymentMethodBreakdown: paymentMethodBreakdown,
      expensesByCategory: expensesByCategory,
      topCategoriesByProfit: topCategoriesByProfit.take(5).toList(),
    );
  }

  /// Bucket values into [DailyDataPoint]s for every day between [rangeStart] and
/// [rangeEnd] (inclusive). Days with no activity get a 0 entry so charts
/// display continuous axes.
List<DailyDataPoint> _bucketDailyBetween<T>(
    List<T> items,
    DateTime rangeStart,
    DateTime rangeEnd, {
    required DateTime Function(T) keyFn,
    required double Function(T) valueFn,
  }) {
    final totals = <DateTime, double>{};
    for (final item in items) {
      final d = keyFn(item);
      final day = DateTime(d.year, d.month, d.day);
      totals.update(day, (v) => v + valueFn(item), ifAbsent: () => valueFn(item));
    }

    final result = <DailyDataPoint>[];
    var cursor = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    final end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
    while (!cursor.isAfter(end)) {
      result.add(DailyDataPoint(date: cursor, value: totals[cursor] ?? 0));
      cursor = cursor.add(const Duration(days: 1));
    }
    return result;
  }
}

class _NamedAccum {
  final String name;
  double value;
  String? subtitle;
  final String? id;

  _NamedAccum({
    required this.name,
    required this.value,
    this.subtitle,
    this.id,
  });
}