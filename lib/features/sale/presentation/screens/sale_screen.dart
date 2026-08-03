import 'package:flutter/material.dart';
import 'package:amar_dokan/shared/widgets/placeholder_screen.dart';

class SaleScreen extends StatelessWidget {
  const SaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Sales',
      icon: Icons.point_of_sale,
      description: 'Create new sales, view history, and manage orders',
      color: Color(0xFF1976D2),
    );
  }
}