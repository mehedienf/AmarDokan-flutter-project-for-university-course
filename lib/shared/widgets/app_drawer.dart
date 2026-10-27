import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';
import 'package:amar_dokan/core/providers/navigation_provider.dart';

import 'package:amar_dokan/features/customers/presentation/screens/customers_screen.dart';
import 'package:amar_dokan/features/suppliers/presentation/screens/suppliers_screen.dart';
import 'package:amar_dokan/features/purchase/presentation/screens/purchase_screen.dart';
import 'package:amar_dokan/features/accounting/presentation/screens/accounting_screen.dart';
import 'package:amar_dokan/features/due/presentation/screens/due_screen.dart';
import 'package:amar_dokan/features/settings/presentation/screens/settings_screen.dart';
import 'package:amar_dokan/features/auth/data/services/auth_service.dart';
import 'package:amar_dokan/features/auth/providers/auth_provider.dart';

/// App Drawer - Side Menu
/// এখান থেকে Drawer based features (Purchase, Accounting, ইত্যাদি) access করা যায়
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

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
          if (isAdmin) const Divider(),
          if (isAdmin)
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

          // Purchase (admin only)
          if (isAdmin)
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

          // Due (admin only)
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Due'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DueScreen()),
                );
              },
            ),

          // Accounting (admin only)
          if (isAdmin)
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

          // Suppliers (admin only)
          if (isAdmin)
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

          // Customers (admin only)
          if (isAdmin)
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

          if (isAdmin) const Divider(),
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

          // Unsubscribe
          ListTile(
            leading: const Icon(Icons.cancel_outlined, color: AppColors.error),
            title: const Text(
              'Unsubscribe',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => _unsubscribe(context),
          ),
        ],
      ),
    );
  }

  Future<void> _unsubscribe(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AuthService.phoneKey) ?? '';

    if (phone.isEmpty) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Phone not found!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unsubscribing'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    Navigator.of(context).pop();
    final navigator = Navigator.of(context);

    var loaderOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    Future<void> closeLoader() async {
      if (!loaderOpen) return;
      loaderOpen = false;
      if (navigator.canPop()) {
        navigator.pop();
      }
    }

    try {
      final response = await http
          .post(
            Uri.parse('${AuthService.bdAppsBaseUrl}unsubscribe.php'),
            body: {'user_mobile': phone},
          )
          .timeout(const Duration(seconds: 15));

      if (!context.mounted) return;
      await closeLoader();
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response shape');
      }

      final statusCode = decoded['statusCode']?.toString() ?? '';
      final statusDetail = decoded['statusDetail']?.toString() ?? '';
      final subscriptionStatus =
          decoded['subscriptionStatus']?.toString().toUpperCase() ?? '';
      final success = decoded['success'] == true ||
          statusCode == 'S1000' ||
          subscriptionStatus == 'UNREGISTERED';

      if (!success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              statusDetail.isNotEmpty
                  ? statusDetail
                  : 'Unsubscribing failed',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      await auth.signOut();
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unsubscribing success!'),
          backgroundColor: Colors.green,
        ),
      );
    } on TimeoutException {
      if (!context.mounted) return;
      await closeLoader();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Timeout error!'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      await closeLoader();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Network error: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
