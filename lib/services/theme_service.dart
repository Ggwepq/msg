import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  // Curated accent palette — no generic reds/blues
  static const List<AccentOption> accentOptions = [
    AccentOption("Lavender",  Color(0xFF9B8FFF), Color(0xFF7C6FE0)),
    AccentOption("Peach",     Color(0xFFFF9A76), Color(0xFFE07850)),
    AccentOption("Mint",      Color(0xFF6EEAB4), Color(0xFF3CC98A)),
    AccentOption("Rose",      Color(0xFFFF7EB3), Color(0xFFE05A90)),
    AccentOption("Sky",       Color(0xFF6EC5FF), Color(0xFF4AA3E0)),
    AccentOption("Honey",     Color(0xFFFFCB57), Color(0xFFE0AA30)),
    AccentOption("Coral",     Color(0xFFFF6F6F), Color(0xFFD94F4F)),
    AccentOption("Lilac",     Color(0xFFC08FFF), Color(0xFFA070E0)),
  ];

  int _accentIndex = 0;
  bool _initialized = false;

  int get accentIndex => _accentIndex;
  AccentOption get accent => accentOptions[_accentIndex];
  Color get primary => accent.primary;
  Color get primaryDark => accent.dark;

  // Core palette
  Color get bg => const Color(0xFF101018);
  Color get surface => const Color(0xFF1A1A26);
  Color get surfaceLight => const Color(0xFF24243A);
  Color get textPrimary => Colors.white;
  Color get textSecondary => Colors.white.withOpacity(0.55);
  Color get textMuted => Colors.white.withOpacity(0.3);
  Color get divider => Colors.white.withOpacity(0.06);

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _accentIndex = (prefs.getInt('accent_index') ?? 0)
        .clamp(0, accentOptions.length - 1);
    _initialized = true;
    notifyListeners();
  }

  Future<void> setAccent(int index) async {
    if (index < 0 || index >= accentOptions.length) return;
    _accentIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accent_index', index);
    notifyListeners();
  }

  ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: primaryDark,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        hintStyle: TextStyle(color: textMuted, fontSize: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class AccentOption {
  final String name;
  final Color primary;
  final Color dark;

  const AccentOption(this.name, this.primary, this.dark);
}
