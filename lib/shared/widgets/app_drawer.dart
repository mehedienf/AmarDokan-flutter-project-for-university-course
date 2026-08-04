import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';
import 'package:amar_dokan/core/providers/navigation_provider.dart';

import 'package:amar_dokan/features/customers/presentation/screens/customers_screen.dart';
import 'package:amar_dokan/features/suppliers/presentation/screens/suppliers_screen.dart';
import 'package:amar_dokan/features/purchase/presentation/screens/purchase_screen.dart';
import 'package:amar_dokan/features/accounting/presentation/screens/accounting_screen.dart';
import 'package:amar_dokan/features/settings/presentation/screens/settings_screen.dart';
import 'package:amar_dokan/features/auth/providers/auth_provider.dart';

/// Helper used by Sign Out tile to confirm before logging out.
Future<bool> _confirmSignOut(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sign out'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Sign out', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// App Drawer - Side Menu
/// এখান থেকে Drawer based features (Purchase, Accounting, ইত্যাদি) access করা যায়
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header - App এর branding দেখায়
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // App Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.store,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                // App Name
                const Text(
                  'Amar Dokan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Inventory & Sales Manager',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Main Menu Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'MAIN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Dashboard
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () => _navigateTo(context, 0),
          ),

          // Sales
          ListTile(
            leading: const Icon(Icons.point_of_sale_outlined),
            title: const Text('Sales'),
            onTap: () => _navigateTo(context, 2),
          ),

          // Divider
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'MANAGEMENT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Purchase
          ListTile(
            leading: const Icon(Icons.shopping_cart_outlined),
            title: const Text('Purchase'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PurchaseScreen()),
              );
            },
          ),

          // Accounting
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Accounting'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountingScreen()),
              );
            },
          ),

          // Suppliers
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined),
            title: const Text('Suppliers'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SuppliersScreen()),
              );
            },
          ),

          // Customers
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Customers'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomersScreen()),
              );
            },
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'PREFERENCES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Settings
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),

          // About
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              _showComingSoon(context, 'About');
            },
          ),

          // Divider
          const Divider(),

          // Sign out
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () async {
              final navigator = Navigator.of(context);
              final rootNavigator =
                  Navigator.of(context, rootNavigator: true);
              final auth = context.read<AuthProvider>();
              final messenger = ScaffoldMessenger.maybeOf(context);
              navigator.pop(); // close drawer
              if (!context.mounted) return;
              final shouldSignOut = await _confirmSignOut(context);
              if (!shouldSignOut) return;

              final ok = await auth.signOut();

              // Flush any pushed screens (Purchase/Accounting/Suppliers/
              // Customers) back to the first route so the AuthGate rebuild
              // is actually visible. Without this, stacked routes linger
              // over the LoginScreen and back navigation lands on a stale
              // authenticated screen.
              if (rootNavigator.canPop()) {
                rootNavigator.popUntil((route) => route.isFirst);
              }

              if (!ok && messenger != null) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Sign out failed. Please try again.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Navigate to a bottom-nav page (closes drawer first)
  void _navigateTo(BuildContext context, int index) {
    Navigator.pop(context);
    context.read<NavigationProvider>().setCurrentIndex(index);
  }

  // এই feature গুলো এখনো বানানো হয়নি, তাই message দেখাচ্ছি
  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: AppColors.info,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
