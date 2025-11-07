import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState with ChangeNotifier {
  final SharedPreferences prefs;
  ThemeMode _themeMode;

  ThemeState(this.prefs) : _themeMode = _loadThemeMode(prefs);

  ThemeMode get themeMode => _themeMode;

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final theme = prefs.getString('theme') ?? 'system';
    return ThemeMode.values.firstWhere((e) => e.toString() == 'ThemeMode.$theme', orElse: () => ThemeMode.system);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await prefs.setString('theme', mode.toString().split('.').last);
    notifyListeners();
  }

  final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    // Add other theme properties as needed
  );

  final ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    // Add other theme properties as needed
  );
}
