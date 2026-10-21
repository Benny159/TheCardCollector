import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcg_collector/core/theme/app_colors.dart';
import 'package:tcg_collector/core/theme/app_theme.dart';
import 'package:tcg_collector/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppColors & Presets', () {
    test('Presets are populated and have valid properties', () {
      expect(AppColors.presets, isNotEmpty);
      expect(AppColors.presets.length, greaterThanOrEqualTo(9));

      final pokeball = AppColors.presetById('pokeball_red');
      expect(pokeball.id, equals('pokeball_red'));
      expect(pokeball.primary, equals(const Color(0xFFE53935)));
    });

    test('Unknown preset ID falls back to pokeballRed', () {
      final fallback = AppColors.presetById('unknown_non_existent');
      expect(fallback.id, equals(AppColors.pokeballRed.id));
    });

    test('Type colors return valid colors', () {
      expect(AppColors.typeColor('Fire'), equals(const Color(0xFFF08030)));
      expect(AppColors.typeColor('Water'), equals(const Color(0xFF6890F0)));
      expect(AppColors.typeColor('unknown'), equals(AppColors.neutral));
      expect(AppColors.typeColor(null), equals(AppColors.neutral));
    });
  });

  group('AppTheme Builder', () {
    test('Light theme creates valid ThemeData with extensions', () {
      final theme = AppTheme.lightTheme(
        primaryColor: AppColors.pokeballRed.primary,
        preset: AppColors.pokeballRed,
      );

      expect(theme.brightness, equals(Brightness.light));
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, equals(AppColors.pokeballRed.primary));

      final ext = theme.extension<AppThemeColors>();
      expect(ext, isNotNull);
      expect(ext!.profit, isNotNull);
      expect(ext.loss, isNotNull);
    });

    test('Dark theme creates valid ThemeData with dark brightness', () {
      final theme = AppTheme.darkTheme(
        primaryColor: AppColors.electricYellow.primary,
        preset: AppColors.electricYellow,
      );

      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.useMaterial3, isTrue);
      expect(theme.scaffoldBackgroundColor, equals(const Color(0xFF0F172A)));

      final ext = theme.extension<AppThemeColors>();
      expect(ext, isNotNull);
    });
  });

  group('ThemeNotifier & State Management', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Default ThemeState is System and Pokéball Red', () {
      final notifier = ThemeNotifier(prefs);
      expect(notifier.state.themeMode, equals(ThemeMode.system));
      expect(notifier.state.presetId, equals(AppColors.pokeballRed.id));
      expect(notifier.state.customPrimaryColor, isNull);
    });

    test('Switching ThemeMode persists to SharedPreferences', () async {
      final notifier = ThemeNotifier(prefs);

      await notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.state.themeMode, equals(ThemeMode.dark));
      expect(prefs.getString('app_theme_mode'), equals('dark'));

      await notifier.setThemeMode(ThemeMode.light);
      expect(notifier.state.themeMode, equals(ThemeMode.light));
      expect(prefs.getString('app_theme_mode'), equals('light'));

      await notifier.toggleThemeMode();
      expect(notifier.state.themeMode, equals(ThemeMode.dark));
    });

    test('Switching presets persists to SharedPreferences', () async {
      final notifier = ThemeNotifier(prefs);

      await notifier.setPreset(AppColors.waterBlue.id);
      expect(notifier.state.presetId, equals(AppColors.waterBlue.id));
      expect(notifier.state.primaryColor, equals(AppColors.waterBlue.primary));
      expect(prefs.getString('app_theme_preset_id'), equals(AppColors.waterBlue.id));
    });

    test('Setting custom primary color overrides preset and persists', () async {
      final notifier = ThemeNotifier(prefs);
      const custom = Color(0xFF9C27B0);

      await notifier.setCustomPrimaryColor(custom);
      expect(notifier.state.customPrimaryColor, equals(custom));
      expect(notifier.state.primaryColor, equals(custom));
      expect(prefs.getInt('app_theme_custom_primary'), equals(custom.toARGB32()));

      // Selecting a preset again clears custom color
      await notifier.setPreset(AppColors.grassGreen.id);
      expect(notifier.state.customPrimaryColor, isNull);
      expect(notifier.state.primaryColor, equals(AppColors.grassGreen.primary));
      expect(prefs.containsKey('app_theme_custom_primary'), isFalse);
    });

    test('Resetting theme restores initial defaults', () async {
      final notifier = ThemeNotifier(prefs);
      await notifier.setThemeMode(ThemeMode.dark);
      await notifier.setCustomPrimaryColor(const Color(0xFF123456));

      await notifier.resetToDefault();
      expect(notifier.state.themeMode, equals(ThemeMode.system));
      expect(notifier.state.presetId, equals(AppColors.pokeballRed.id));
      expect(notifier.state.customPrimaryColor, isNull);
    });
  });
}
