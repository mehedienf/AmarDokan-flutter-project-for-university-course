import 'package:flutter/material.dart';

/// Stock filter options for inventory list
enum StockFilter {
  all,
  inStock,
  lowStock,
  outOfStock,
}

extension StockFilterExtension on StockFilter {
  String get label {
    switch (this) {
      case StockFilter.all:
        return 'All';
      case StockFilter.inStock:
        return 'In Stock';
      case StockFilter.lowStock:
        return 'Low Stock';
      case StockFilter.outOfStock:
        return 'Out of Stock';
    }
  }

  IconData get icon {
    switch (this) {
      case StockFilter.all:
        return Icons.inventory_2_outlined;
      case StockFilter.inStock:
        return Icons.check_circle_outline;
      case StockFilter.lowStock:
        return Icons.warning_amber_outlined;
      case StockFilter.outOfStock:
        return Icons.error_outline;
    }
  }
}

/// Sort options for inventory list
enum SortOption {
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
  stockAsc,
  stockDesc,
  newest,
}

extension SortOptionExtension on SortOption {
  String get label {
    switch (this) {
      case SortOption.nameAsc:
        return 'Name (A-Z)';
      case SortOption.nameDesc:
        return 'Name (Z-A)';
      case SortOption.priceAsc:
        return 'Price (Low-High)';
      case SortOption.priceDesc:
        return 'Price (High-Low)';
      case SortOption.stockAsc:
        return 'Stock (Low-High)';
      case SortOption.stockDesc:
        return 'Stock (High-Low)';
      case SortOption.newest:
        return 'Newest First';
    }
  }

  IconData get icon {
    switch (this) {
      case SortOption.nameAsc:
      case SortOption.nameDesc:
        return Icons.sort_by_alpha;
      case SortOption.priceAsc:
      case SortOption.priceDesc:
        return Icons.attach_money;
      case SortOption.stockAsc:
      case SortOption.stockDesc:
        return Icons.inventory;
      case SortOption.newest:
        return Icons.access_time;
    }
  }
}