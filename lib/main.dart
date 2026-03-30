import 'package:flutter/material.dart';
import 'package:amar_dokan/providers/product_provider.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ProductProvider()),
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
        primarySwatch: Colors.blue,
        // bottomAppBarColor: Colors.white,
      ),
      title: 'AmarDokan',
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
