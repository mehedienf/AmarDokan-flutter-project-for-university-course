import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/providers/navigation_provider.dart';

class BottomNavbar extends StatelessWidget {
  const BottomNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    // final navigationProvider = Provider.of<NavigationProvider>(context);
    final navigationProvider = context.watch<NavigationProvider>();

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      showUnselectedLabels: true,
      currentIndex: navigationProvider.currentIndex,
      onTap: (index) => navigationProvider.setCurrentIndex(index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory),
          label: 'Inventory',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.sell), label: 'Sales'),
        BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Report'),
      ],
    );
  }
}
