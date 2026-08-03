import 'package:flutter/material.dart';

import 'package:amar_dokan/models/page_model.dart';

import 'package:provider/provider.dart';
import 'package:amar_dokan/core/providers/navigation_provider.dart';
import 'package:amar_dokan/core/constants/app_colors.dart';

import 'package:amar_dokan/shared/widgets/bottom_navbar.dart';
import 'package:amar_dokan/shared/widgets/app_drawer.dart';

import 'package:amar_dokan/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:amar_dokan/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:amar_dokan/features/report/presentation/screens/report_screen.dart';
import 'package:amar_dokan/features/sales/presentation/screens/sales_screen.dart';
import 'package:amar_dokan/features/auth/providers/auth_provider.dart';
import 'package:amar_dokan/features/auth/presentation/screens/login_screen.dart';

/// Top-level gate that picks Splash / Login / MainApp based on auth state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isInitialized) {
      return const _SplashScreen();
    }
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }
    return const MainApp();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(48),
              ),
              child: const Icon(Icons.store, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Amar Dokan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

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
