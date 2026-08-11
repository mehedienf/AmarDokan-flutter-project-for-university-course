import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:amar_dokan/firebase_options.dart';

import 'package:amar_dokan/features/inventory/providers/inventory_provider.dart';
import 'package:amar_dokan/features/customers/providers/customer_provider.dart';
import 'package:amar_dokan/features/suppliers/providers/supplier_provider.dart';
import 'package:amar_dokan/features/sales/providers/sale_provider.dart';
import 'package:amar_dokan/features/purchase/providers/purchase_provider.dart';
import 'package:amar_dokan/features/accounting/providers/transaction_provider.dart';
import 'package:amar_dokan/features/auth/providers/auth_provider.dart';
import 'package:amar_dokan/core/providers/navigation_provider.dart';
import 'package:amar_dokan/core/providers/theme_provider.dart';
import 'package:amar_dokan/core/theme/app_theme.dart';
import 'package:amar_dokan/features/report/providers/report_provider.dart';
import 'package:amar_dokan/features/dashboard/providers/dashboard_provider.dart';
import 'package:amar_dokan/app/app.dart';

void main() async {
  // Flutter এ async কাজ করার আগে WidgetsFlutterBinding ensure করতে হয়
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialize 
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ThemeProvider initialize করে SharedPreferences থেকে saved theme mode
  // load করা হচ্ছে, যাতে প্রথম frame থেকেই user এর পছন্দ apply হয়।
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        // ReportProvider reads from Sale/Purchase/Transaction/Inventory above
        // when recompute() is called, so it must come after them.
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        // DashboardProvider also reads from the source providers above when
        // recompute() is called.
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Amar Dokan',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const AuthGate(),
    );
  }
}
