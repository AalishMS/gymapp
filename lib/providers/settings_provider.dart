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

  static const Color defaultAccent = Color(0xFF00FF41);
  ThemeMode _themeMode = ThemeMode.dark;
  Color _accentColor = defaultAccent;
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
        name: 'MATRIX GREEN',
        color: Color(0xFF00FF41),
        seed: Color(0xFF00FF41)),
    AccentColorOption(
        name: 'TERMINAL BLUE',
        color: Color(0xFF00BFFF),
        seed: Color(0xFF00BFFF)),
    AccentColorOption(
        name: 'AMBER', color: Color(0xFFFF6600), seed: Color(0xFFFF6600)),
    AccentColorOption(
        name: 'MAGENTA', color: Color(0xFFFF00FF), seed: Color(0xFFFF00FF)),
    AccentColorOption(
        name: 'GHOST WHITE', color: Color(0xFFFFFFFF), seed: Color(0xFFFFFFFF)),
  ];

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_themeKey) ?? 2;
    _themeMode = ThemeMode.values[themeIndex];

    final accentColorIndex = prefs.getInt(_accentColorKey) ?? 0;
    if (accentColorIndex >= 0 && accentColorIndex < accentColors.length) {
      _accentColor = accentColors[accentColorIndex].color;
    } else {
      _accentColor = defaultAccent;
    }

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
