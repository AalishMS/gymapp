import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _refreshRateChannel = MethodChannel('com.example.gymapp/refresh_rate');

class SettingsProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';
  static const String _weightUnitKey = 'weight_unit';
  static const String _autoFillKey = 'auto_fill_last';
  static const String _highRefreshRateKey = 'high_refresh_rate';

  ThemeMode _themeMode = ThemeMode.dark;
  Color _accentColor = Colors.blue;
  String _weightUnit = 'kg';
  bool _autoFillLast = true;
  bool _highRefreshRate = true;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  String get weightUnit => _weightUnit;
  bool get autoFillLast => _autoFillLast;
  bool get highRefreshRate => _highRefreshRate;

  static const List<AccentColorOption> accentColors = [
    AccentColorOption(
        name: 'Blue', color: Colors.blue, seed: Color(0xFF2196F3)),
    AccentColorOption(
        name: 'Purple', color: Colors.purple, seed: Color(0xFF9C27B0)),
    AccentColorOption(
        name: 'Teal', color: Colors.teal, seed: Color(0xFF009688)),
    AccentColorOption(
        name: 'Orange', color: Colors.orange, seed: Color(0xFFFF9800)),
    AccentColorOption(
        name: 'Pink', color: Colors.pink, seed: Color(0xFFE91E63)),
    AccentColorOption(
        name: 'Green', color: Colors.green, seed: Color(0xFF4CAF50)),
    AccentColorOption(name: 'Red', color: Colors.red, seed: Color(0xFFF44336)),
    AccentColorOption(
        name: 'Amber', color: Colors.amber, seed: Color(0xFFFFC107)),
    AccentColorOption(
        name: 'Cyan', color: Colors.cyan, seed: Color(0xFF00BCD4)),
    AccentColorOption(
        name: 'Indigo', color: Colors.indigo, seed: Color(0xFF3F51B5)),
    AccentColorOption(
        name: 'Gray', color: Colors.grey, seed: Color(0xFF607D8B)),
  ];

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_themeKey) ?? 2;
    _themeMode = ThemeMode.values[themeIndex];

    final accentColorIndex = prefs.getInt(_accentColorKey) ?? 0;
    _accentColor = accentColors[accentColorIndex].color;

    _weightUnit = prefs.getString(_weightUnitKey) ?? 'kg';
    _autoFillLast = prefs.getBool(_autoFillKey) ?? true;
    _highRefreshRate = prefs.getBool(_highRefreshRateKey) ?? true;

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    notifyListeners();
  }

  Future<void> setAccentColor(int index) async {
    if (index >= 0 && index < accentColors.length) {
      _accentColor = accentColors[index].color;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_accentColorKey, index);
      notifyListeners();
    }
  }

  int getAccentColorIndex() {
    return accentColors.indexWhere((c) => c.color == _accentColor);
  }

  Color getAccentSeed() {
    final index = getAccentColorIndex();
    if (index < 0 || index >= accentColors.length) {
      return accentColors[0].seed;
    }
    return accentColors[index].seed;
  }

  Future<void> setWeightUnit(String unit) async {
    _weightUnit = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weightUnitKey, unit);
    notifyListeners();
  }

  Future<void> setAutoFillLast(bool value) async {
    _autoFillLast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoFillKey, value);
    notifyListeners();
  }

  Future<void> setHighRefreshRate(bool value) async {
    _highRefreshRate = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highRefreshRateKey, value);
    try {
      await _refreshRateChannel.invokeMethod('setHighRefreshRate', value);
    } catch (e) {
      debugPrint('Failed to set high refresh rate: $e');
    }
    notifyListeners();
  }
}

class AccentColorOption {
  final String name;
  final Color color;
  final Color seed;

  const AccentColorOption({
    required this.name,
    required this.color,
    required this.seed,
  });
}
