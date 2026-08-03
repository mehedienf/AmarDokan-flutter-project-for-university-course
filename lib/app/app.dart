import 'package:flutter/material.dart';

import 'package:amar_dokan/models/page_model.dart';

import 'package:provider/provider.dart';
import 'package:amar_dokan/core/providers/navigation_provider.dart';

import 'package:amar_dokan/shared/widgets/bottom_navbar.dart';
import 'package:amar_dokan/shared/widgets/app_drawer.dart';

import 'package:amar_dokan/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:amar_dokan/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:amar_dokan/features/report/presentation/screens/report_screen.dart';
import 'package:amar_dokan/features/sales/presentation/screens/sales_screen.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MyAppState();
}

class _MyAppState extends State<MainApp> {
  final List<Pages> _pages = [
    Pages('Dashboard', DashboardScreen()),
    Pages('Inventory', InventoryScreen()),
    Pages('Sales', SalesScreen()),
    Pages('Report', ReportScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final navigationProvider = context.watch<NavigationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pages[navigationProvider.currentIndex].title,
          style: TextStyle(fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: IndexedStack(
        // IndexedStack use korchi jate page switch korar somoy state maintain thake, jodi amra direct page.page use kortam tahole page switch korar somoy state loss hoye jeto
        index: navigationProvider.currentIndex,
        children: _pages.map((page) => page.page).toList(),
      ),
      drawer: AppDrawer(),
      bottomNavigationBar: const BottomNavbar(),
    );
  }
}
