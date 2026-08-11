import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/core/providers/navigation_provider.dart';
import 'package:amar_dokan/features/auth/providers/auth_provider.dart';

class BottomNavbar extends StatelessWidget {
  const BottomNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    // final navigationProvider = Provider.of<NavigationProvider>(context);
    final navigationProvider = context.watch<NavigationProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    // Staff see only Dashboard + Sales (indices 0, 2).
    // Admin sees Dashboard + Inventory + Sales + Report.
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.inventory),
          label: 'Inventory',
        ),
      const BottomNavigationBarItem(icon: Icon(Icons.sell), label: 'Sales'),
      if (isAdmin)
        const BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Report'),
    ];

    // Clamp currentIndex so it never points past the visible items.
    var safeIndex = navigationProvider.currentIndex;
    if (safeIndex < 0 || safeIndex >= items.length) {
      safeIndex = 0;
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      showUnselectedLabels: true,
      currentIndex: safeIndex,
      onTap: (index) => navigationProvider.setCurrentIndex(index),
      items: items,
    );
  }
}
