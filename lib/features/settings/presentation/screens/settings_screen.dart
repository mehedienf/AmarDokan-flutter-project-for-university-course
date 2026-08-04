import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/core/providers/theme_provider.dart';

/// Settings screen — currently exposes a Light / Dark / System
/// theme switcher. The selection is stored in [ThemeProvider] and
/// reactively applied by `MaterialApp` in `main.dart`.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'APPEARANCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.brightness_6_outlined),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Theme mode',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose how Amar Dokan appears on this device.',
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto_outlined),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {themeProvider.themeMode},
                    onSelectionChanged: (selection) {
                      context
                          .read<ThemeProvider>()
                          .setThemeMode(selection.first);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}