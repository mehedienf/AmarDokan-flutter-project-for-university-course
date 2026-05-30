import 'package:amar_dokan/widgets/bottom_navbar.dart';
import 'package:flutter/material.dart';

import 'package:amar_dokan/models/page_model.dart';

import 'package:provider/provider.dart';
import 'package:amar_dokan/providers/navigation_provider.dart';

import 'package:amar_dokan/screens/dashboard_screen.dart';
import 'package:amar_dokan/screens/inventory_screen.dart';
import 'package:amar_dokan/screens/report_screen.dart';
import 'package:amar_dokan/screens/sales_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        title: Text(_pages[navigationProvider.currentIndex].title, style: TextStyle(fontSize: 22)),
        centerTitle: true,
      ),
      body: IndexedStack(
        // IndexedStack use korchi jate page switch korar somoy state maintain thake, jodi amra direct page.page use kortam tahole page switch korar somoy state loss hoye jeto
        index: navigationProvider.currentIndex,
        children: _pages.map((page) => page.page).toList(),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(child: Text('InvoSys')),
            ListTile(
              leading: Icon(Icons.star, color: Colors.amber),
              title: Text('Home'),
              subtitle: Text('Dashboard Screen'),
              trailing: Icon(Icons.chevron_right),
              selectedTileColor: Colors.grey.shade200,
              onTap: () {},
              selected: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavbar(),
    );
  }
}
