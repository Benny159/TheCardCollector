import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'app_theme.dart';

/// Provider für die SharedPreferences Instanz.
/// Wird in main() via `sharedPreferencesProvider.overrideWithValue(prefs)` initialisiert.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider muss in main() via overrideWithValue initialisiert werden.',
  );
});

/// Repräsentiert den aktuellen Theme- und Farbzustand der App.
class ThemeState {
  final ThemeMode themeMode;
  final String presetId;
  final Color? customPrimaryColor;

  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.presetId = 'pokeball_red',
    this.customPrimaryColor,
  });

  /// Gibt das aktive Farbpreset zurück.
  AppColorPreset get currentPreset => AppColors.presetById(presetId);

  /// Gibt die tatsächliche Primärfarbe zurück (Custom oder Preset).
  Color get primaryColor => customPrimaryColor ?? currentPreset.primary;

  /// Erzeugt das passende Light Theme.
  ThemeData get lightTheme => AppTheme.lightTheme(
        primaryColor: primaryColor,
        preset: customPrimaryColor == null ? currentPreset : null,
      );

  /// Erzeugt das passende Dark Theme.
  ThemeData get darkTheme => AppTheme.darkTheme(
        primaryColor: primaryColor,
        preset: customPrimaryColor == null ? currentPreset : null,
      );

  ThemeState copyWith({
    ThemeMode? themeMode,
    String? presetId,
    Color? customPrimaryColor,
    bool clearCustomColor = false,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      presetId: presetId ?? this.presetId,
      customPrimaryColor: clearCustomColor
          ? null
          : (customPrimaryColor ?? this.customPrimaryColor),
    );
  }
}

/// Verwaltet den ThemeMode (System / Hell / Dunkel) sowie die Farbpalette
/// und speichert Änderungen dauerhaft in den SharedPreferences.
class ThemeNotifier extends StateNotifier<ThemeState> {
  final SharedPreferences _prefs;

  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyPresetId = 'app_theme_preset_id';
  static const String _keyCustomPrimary = 'app_theme_custom_primary';

  ThemeNotifier(this._prefs) : super(const ThemeState()) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    // 1. ThemeMode laden
    final savedModeString = _prefs.getString(_keyThemeMode);
    ThemeMode mode = ThemeMode.system;
    if (savedModeString == 'light') {
      mode = ThemeMode.light;
    } else if (savedModeString == 'dark') {
      mode = ThemeMode.dark;
    }

    // 2. Preset laden
    final savedPresetId =
        _prefs.getString(_keyPresetId) ?? AppColors.pokeballRed.id;

    // 3. Eigene Primärfarbe laden
    final savedCustomColorInt = _prefs.getInt(_keyCustomPrimary);
    final customColor =
        savedCustomColorInt != null ? Color(savedCustomColorInt) : null;

    state = ThemeState(
      themeMode: mode,
      presetId: savedPresetId,
      customPrimaryColor: customColor,
    );
  }

  /// Ändert den ThemeMode (System, Light, Dark).
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final modeString = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await _prefs.setString(_keyThemeMode, modeString);
  }

  /// Schnell-Umschalter zwischen Hell und Dunkel
  Future<void> toggleThemeMode() async {
    if (state.themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  /// Wählt eines der vordefinierten TCG-Themes aus
  Future<void> setPreset(String presetId) async {
    state = state.copyWith(
      presetId: presetId,
      clearCustomColor: true,
    );
    await _prefs.setString(_keyPresetId, presetId);
    await _prefs.remove(_keyCustomPrimary);
  }

  /// Wählt eine individuelle Primärfarbe aus
  Future<void> setCustomPrimaryColor(Color color) async {
    state = state.copyWith(
      customPrimaryColor: color,
    );
    await _prefs.setInt(_keyCustomPrimary, color.toARGB32());
  }

  /// Setzt das Theme auf die Werkseinstellungen zurück
  Future<void> resetToDefault() async {
    state = const ThemeState();
    await _prefs.remove(_keyThemeMode);
    await _prefs.remove(_keyPresetId);
    await _prefs.remove(_keyCustomPrimary);
  }
}

/// Haupt-Provider für den Theme-Zustand
final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

/// Hilfs-Provider für den aktuellen ThemeMode
final currentThemeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeNotifierProvider).themeMode;
});

/// Hilfs-Provider für die aktuelle Primärfarbe
final currentPrimaryColorProvider = Provider<Color>((ref) {
  return ref.watch(themeNotifierProvider).primaryColor;
});
