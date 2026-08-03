import 'package:flutter/material.dart';
import 'package:amar_dokan/shared/widgets/placeholder_screen.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Reports',
      icon: Icons.analytics,
      description: 'Sales, purchase, and profit reports will appear here',
      color: Color(0xFFF57C00),
    );
  }
}