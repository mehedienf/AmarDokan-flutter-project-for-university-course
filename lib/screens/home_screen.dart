import 'package:flutter/material.dart';
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
  int _currentIndex = 0;

  final List<Widget> _pages = [
    DashboardScreen(),
    InventoryScreen(),
    SalesScreen(),
    ReportScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Inventory',
    'Sales',
    'Report',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: _pages[_currentIndex],
      // bottomNavigationBar: MyBottomNavBar(currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i),),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: _currentIndex, // Set the current index
        onTap: (index) {
          setState(() => _currentIndex = index);
        }, // Update the current index on tap
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.sell), label: 'Sales'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Report'),
        ],
      ),
    );
  }
}
