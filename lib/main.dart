import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:amar_dokan/providers/product_provider.dart';
import 'package:amar_dokan/providers/navigation_provider.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ProductProvider()),
      ChangeNotifierProvider(create: (_) => NavigationProvider()),
    ],
    child: const MainApp(title: 'AmarDokan'),
  ));
}

class MainApp extends StatelessWidget {
  final String title;
  const MainApp({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: const Color.fromARGB(255, 88, 66, 229),
          secondary: Colors.blueAccent,
        ),
        // bottomAppBarColor: Colors.white,
      ),
      themeMode: ThemeMode.light,
      title: 'AmarDokan',
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
