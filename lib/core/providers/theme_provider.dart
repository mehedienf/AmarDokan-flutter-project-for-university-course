import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide theme mode provider. Tracks whether the user has chosen
/// Light, Dark, or to follow the System theme. The selection is
/// persisted to [SharedPreferences] under [_prefsKey] so it survives
/// app restarts.
class ThemeProvider extends ChangeNotifier {
  static const String _prefsKey = 'app.theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _initialized = false;

  ThemeMode get themeMode => _themeMode;

  /// Whether the saved theme has been loaded from disk. While false,
  /// the app can show a splash and avoid flashing the default theme.
  bool get isInitialized => _initialized;

  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isLight => _themeMode == ThemeMode.light;
  bool get isSystem => _themeMode == ThemeMode.system;

  /// Load the saved [ThemeMode] from [SharedPreferences]. Must be
  /// awaited once before `runApp` so the saved choice is applied on
  /// the very first frame.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    _themeMode = _decode(raw) ?? ThemeMode.system;
    _initialized = true;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    // Fire-and-forget persistence; SharedPreferences writes are cheap
    // and we don't want to block the UI thread on them.
    _persist(mode);
  }

  Future<void> _persist(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _encode(mode));
  }

  static ThemeMode? _decode(String? value) {
    switch (value) {
      case 'system':
        return ThemeMode.system;
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return null;
    }
  }

  static String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
    }
  }
}
