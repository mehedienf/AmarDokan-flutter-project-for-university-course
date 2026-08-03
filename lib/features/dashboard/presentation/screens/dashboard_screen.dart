import 'package:flutter/material.dart';
import 'package:amar_dokan/shared/widgets/placeholder_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Dashboard',
      icon: Icons.dashboard,
      description: 'Today\'s sales, profit, and stock summary will appear here',
    );
  }
}