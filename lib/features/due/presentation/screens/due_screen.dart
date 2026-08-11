import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';
import 'package:amar_dokan/features/customers/presentation/screens/customer_details_screen.dart';
import 'package:amar_dokan/features/customers/providers/customer_provider.dart';
import 'package:amar_dokan/features/purchase/providers/purchase_provider.dart';
import 'package:amar_dokan/features/sales/providers/sale_provider.dart';
import 'package:amar_dokan/features/suppliers/presentation/screens/supplier_details_screen.dart';
import 'package:amar_dokan/features/suppliers/providers/supplier_provider.dart';

/// Due screen — lists customers who owe us money and suppliers we owe.
///
/// Per-contact due is derived live from SaleProvider / PurchaseProvider, so
/// no extra Firestore writes are needed when payments are recorded.
class DueScreen extends StatefulWidget {
  const DueScreen({super.key});

  @override
  State<DueScreen> createState() => _DueScreenState();
}

class _DueScreenState extends State<DueScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Make sure both providers are streaming — the screen reads from their
    // live lists so the counters stay in sync with new sales / purchases.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SaleProvider>().startListening();
      context.read<PurchaseProvider>().startListening();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Warm orange-ish for Customers (you owe them), cool teal for Suppliers
    // (they owe you / you owe them). Strong contrast against the AppBar in
    // both light and dark modes.
    const customerColor = Color(0xFFE65100); // deep orange 900
    const supplierColor = Color(0xFF00695C); // teal 800

    return Scaffold(
      appBar: AppBar(
        title: const Text('Due'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              final t = (_tabController.animation?.value ?? 0.0);
              // Smoothly interpolate between the two brand colors as the
              // user swipes or taps between tabs.
              final activeColor = Color.lerp(
                customerColor,
                supplierColor,
                t,
              )!;
              return TabBar(
                controller: _tabController,
                labelColor: activeColor,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: activeColor,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(
                    text: 'Customers',
                    icon: Icon(Icons.people_outline, color: customerColor),
                  ),
                  Tab(
                    text: 'Suppliers',
                    icon: Icon(
                      Icons.local_shipping_outlined,
                      color: supplierColor,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CustomerDueList(),
          _SupplierDueList(),
        ],
      ),
    );
  }
}

/// Aggregated due row used by both lists.
class _DueRow {
  final String id;
  final String name;
  final String subtitle;
  final double due;
  final int openCount;

  const _DueRow({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.due,
    required this.openCount,
  });
}

class _CustomerDueList extends StatelessWidget {
  const _CustomerDueList();

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>().customers;
    final sales = context.watch<SaleProvider>().sales;

    final rows = <_DueRow>[];
    for (final customer in customers) {
      final due = sales
          .where((s) => s.customerId == customer.id && s.balance > 0)
          .fold<double>(0, (sum, s) => sum + s.balance);
      final openCount =
          sales.where((s) => s.customerId == customer.id && s.balance > 0).length;
      if (due > 0) {
        rows.add(_DueRow(
          id: customer.id,
          name: customer.name,
          subtitle: customer.phone,
          due: due,
          openCount: openCount,
        ));
      }
    }
    rows.sort((a, b) => b.due.compareTo(a.due));

    final totalDue = rows.fold<double>(0, (sum, r) => sum + r.due);

    return _DueListBody(
      emptyText: 'No customers owe you right now.',
      totalDue: totalDue,
      rows: rows,
      onTap: (row) {
        final customer = context
            .read<CustomerProvider>()
            .customers
            .firstWhere((c) => c.id == row.id);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomerDetailsScreen(customer: customer),
          ),
        );
      },
    );
  }
}

class _SupplierDueList extends StatelessWidget {
  const _SupplierDueList();

  @override
  Widget build(BuildContext context) {
    final suppliers = context.watch<SupplierProvider>().suppliers;
    final purchases = context.watch<PurchaseProvider>().purchases;

    final rows = <_DueRow>[];
    for (final supplier in suppliers) {
      final due = purchases
          .where((p) => p.supplierId == supplier.id && p.balance > 0)
          .fold<double>(0, (sum, p) => sum + p.balance);
      final openCount = purchases
          .where((p) => p.supplierId == supplier.id && p.balance > 0)
          .length;
      if (due > 0) {
        rows.add(_DueRow(
          id: supplier.id,
          name: supplier.displayName,
          subtitle: supplier.phone,
          due: due,
          openCount: openCount,
        ));
      }
    }
    rows.sort((a, b) => b.due.compareTo(a.due));

    final totalDue = rows.fold<double>(0, (sum, r) => sum + r.due);

    return _DueListBody(
      emptyText: 'You owe no suppliers right now.',
      totalDue: totalDue,
      rows: rows,
      onTap: (row) {
        final supplier = context
            .read<SupplierProvider>()
            .suppliers
            .firstWhere((s) => s.id == row.id);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SupplierDetailsScreen(supplier: supplier),
          ),
        );
      },
    );
  }
}

class _DueListBody extends StatelessWidget {
  final String emptyText;
  final double totalDue;
  final List<_DueRow> rows;
  final void Function(_DueRow) onTap;

  const _DueListBody({
    required this.emptyText,
    required this.totalDue,
    required this.rows,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: AppColors.success.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              const Text(
                'All settled!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptyText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          color: AppColors.background,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total due',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'BDT ${totalDue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${rows.length} contact${rows.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24, top: 4),
            itemCount: rows.length,
            itemBuilder: (ctx, i) => _DueTile(row: rows[i], onTap: onTap),
          ),
        ),
      ],
    );
  }
}

class _DueTile extends StatelessWidget {
  final _DueRow row;
  final void Function(_DueRow) onTap;

  const _DueTile({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: () => onTap(row),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    AppColors.error.withValues(alpha: 0.12),
                child: Text(
                  _initials(row.name),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      row.subtitle.isEmpty
                          ? '${row.openCount} unpaid invoice'
                              '${row.openCount == 1 ? '' : 's'}'
                          : '${row.openCount} unpaid invoice'
                              '${row.openCount == 1 ? '' : 's'} • ${row.subtitle}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'BDT ${row.due.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
