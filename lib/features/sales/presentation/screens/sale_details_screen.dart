import 'package:flutter/material.dart';

import '../../data/models/sale_model.dart';

class SaleDetailsScreen extends StatelessWidget {
  final SaleModel sale;

  const SaleDetailsScreen({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(sale.invoiceNumber)),
      body: const Center(child: Text('Sale Details — coming soon')),
    );
  }
}
