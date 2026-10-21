import 'package:flutter/material.dart';

/// Repräsentiert ein vorkonfiguriertes Farb-Theme für die TCG Collector App.
class AppColorPreset {
  final String id;
  final String name;
  final String subtitle;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final IconData icon;

  const AppColorPreset({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.icon,
  });
}

/// Zentrale Farbdefinitionen und Farbpaletten für die App.
/// Hier können Entwickler und Nutzer alle primären, sekundären
/// und semantischen Farben für die gesamte App anpassen.
class AppColors {
  AppColors._();

  // ===========================================================================
  // Vordefinierte TCG & Pokémon Farb-Themes
  // ===========================================================================
  static const AppColorPreset pokeballRed = AppColorPreset(
    id: 'pokeball_red',
    name: 'Pokéball Rot',
    subtitle: 'Klassisches Pokémon-Rot mit kräftigem Akzent',
    primary: Color(0xFFE53935),
    secondary: Color(0xFF1E88E5),
    tertiary: Color(0xFFFFB300),
    icon: Icons.catching_pokemon,
  );

  static const AppColorPreset electricYellow = AppColorPreset(
    id: 'electric_yellow',
    name: 'Pikachu Gelb',
    subtitle: 'Dynamisches Elektro-Gelb & warmer Bernstein',
    primary: Color(0xFFF59E0B),
    secondary: Color(0xFF3B82F6),
    tertiary: Color(0xFFEF4444),
    icon: Icons.bolt,
  );

  static const AppColorPreset waterBlue = AppColorPreset(
    id: 'water_blue',
    name: 'Turtok Blau',
    subtitle: 'Frisches Ozeanblau & kühles Cyan',
    primary: Color(0xFF0284C7),
    secondary: Color(0xFF06B6D4),
    tertiary: Color(0xFF10B981),
    icon: Icons.water_drop,
  );

  static const AppColorPreset grassGreen = AppColorPreset(
    id: 'grass_green',
    name: 'Bisaflor Grün',
    subtitle: 'Natürliches Blattgrün & Smaragd',
    primary: Color(0xFF16A34A),
    secondary: Color(0xFF0D9488),
    tertiary: Color(0xFF84CC16),
    icon: Icons.eco,
  );

  static const AppColorPreset psychicPurple = AppColorPreset(
    id: 'psychic_purple',
    name: 'Gengar Violett',
    subtitle: 'Geheimnisvolles Psycho-Purpur',
    primary: Color(0xFF7C3AED),
    secondary: Color(0xFFEC4899),
    tertiary: Color(0xFF6366F1),
    icon: Icons.auto_awesome,
  );

  static const AppColorPreset fireOrange = AppColorPreset(
    id: 'fire_orange',
    name: 'Glurak Orange',
    subtitle: 'Feuriges Flammen-Orange & Glut',
    primary: Color(0xFFEA580C),
    secondary: Color(0xFFDC2626),
    tertiary: Color(0xFFF59E0B),
    icon: Icons.local_fire_department,
  );

  static const AppColorPreset midnightSlate = AppColorPreset(
    id: 'midnight_slate',
    name: 'Nachtara Slate',
    subtitle: 'Edles Anthrazit & dezentes Dunkelgrau',
    primary: Color(0xFF475569),
    secondary: Color(0xFF38BDF8),
    tertiary: Color(0xFFFBBF24),
    icon: Icons.dark_mode,
  );

  static const AppColorPreset mewPink = AppColorPreset(
    id: 'mew_pink',
    name: 'Mew Rosa',
    subtitle: 'Zauberhaftes Magie-Pink & Magenta',
    primary: Color(0xFFDB2777),
    secondary: Color(0xFF8B5CF6),
    tertiary: Color(0xFFF472B6),
    icon: Icons.favorite,
  );

  static const AppColorPreset emeraldTeal = AppColorPreset(
    id: 'emerald_teal',
    name: 'Rayquaza Smaragd',
    subtitle: 'Tiefes Smaragdgrün & Türkis',
    primary: Color(0xFF0D9488),
    secondary: Color(0xFFEAB308),
    tertiary: Color(0xFF14B8A6),
    icon: Icons.diamond,
  );

  /// Liste aller verfügbaren Preset-Themes
  static const List<AppColorPreset> presets = [
    pokeballRed,
    electricYellow,
    waterBlue,
    grassGreen,
    psychicPurple,
    fireOrange,
    midnightSlate,
    mewPink,
    emeraldTeal,
  ];

  static AppColorPreset presetById(String id) {
    return presets.firstWhere(
      (p) => p.id == id,
      orElse: () => pokeballRed,
    );
  }

  // ===========================================================================
  // Zusätzliche Auswahl für eigene Akzentfarben (Custom Color Swatches)
  // ===========================================================================
  static const List<Color> customColorPalette = [
    Color(0xFFE53935), // Rot
    Color(0xFFEA580C), // Orange
    Color(0xFFF59E0B), // Bernstein / Gold
    Color(0xFF16A34A), // Grün
    Color(0xFF0D9488), // Türkis
    Color(0xFF0284C7), // Hellblau
    Color(0xFF2563EB), // Königsblau
    Color(0xFF7C3AED), // Violett
    Color(0xFFDB2777), // Pink
    Color(0xFF475569), // Schiefer
    Color(0xFF059669), // Smaragd
    Color(0xFFD97706), // Ocker
  ];

  // ===========================================================================
  // Semantische Markt- & Statusfarben
  // ===========================================================================
  static const Color profit = Color(0xFF16A34A);
  static const Color loss = Color(0xFFDC2626);
  static const Color neutral = Color(0xFF64748B);

  // ===========================================================================
  // Pokémon Typen-Farben
  // ===========================================================================
  static const Map<String, Color> typeColors = {
    'normal': Color(0xFFA8A878),
    'fire': Color(0xFFF08030),
    'water': Color(0xFF6890F0),
    'grass': Color(0xFF78C850),
    'electric': Color(0xFFF8D030),
    'ice': Color(0xFF98D8D8),
    'fighting': Color(0xFFC03028),
    'poison': Color(0xFFA040A0),
    'ground': Color(0xFFE0C068),
    'flying': Color(0xFFA890F0),
    'psychic': Color(0xFFF85888),
    'bug': Color(0xFFA8B820),
    'rock': Color(0xFFB8A038),
    'ghost': Color(0xFF705898),
    'dragon': Color(0xFF7038F8),
    'steel': Color(0xFFB8B8D0),
    'darkness': Color(0xFF705848),
    'fairy': Color(0xFFEE99AC),
  };

  static Color typeColor(String? typeName) {
    if (typeName == null) return neutral;
    final normalized = typeName.toLowerCase().trim();
    return typeColors[normalized] ?? neutral;
  }
}

/// ThemeExtension für maßgeschneiderte semantische Farben,
/// die direkt über `Theme.of(context).extension<AppThemeColors>()`
/// oder den BuildContext-Shortcut `context.appColors` abrufbar sind.
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color profit;
  final Color loss;
  final Color cardBackground;
  final Color cardBorder;
  final Color surfaceSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color goldAccent;
  final Color silverAccent;
  final Color bronzeAccent;
  final Color binderBadgeBackground;

  const AppThemeColors({
    required this.profit,
    required this.loss,
    required this.cardBackground,
    required this.cardBorder,
    required this.surfaceSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.goldAccent,
    required this.silverAccent,
    required this.bronzeAccent,
    required this.binderBadgeBackground,
  });

  /// Vorkonfiguration für den Light Mode
  factory AppThemeColors.light() {
    return const AppThemeColors(
      profit: Color(0xFF16A34A),
      loss: Color(0xFFDC2626),
      cardBackground: Colors.white,
      cardBorder: Color(0xFFE2E8F0),
      surfaceSubtle: Color(0xFFF8FAFC),
      textPrimary: Color(0xFF0F172A),
      textSecondary: Color(0xFF475569),
      textMuted: Color(0xFF94A3B8),
      goldAccent: Color(0xFFF59E0B),
      silverAccent: Color(0xFF94A3B8),
      bronzeAccent: Color(0xFFB45309),
      binderBadgeBackground: Color(0xFFEEF2FF),
    );
  }

  /// Vorkonfiguration für den Dark Mode
  factory AppThemeColors.dark() {
    return const AppThemeColors(
      profit: Color(0xFF22C55E),
      loss: Color(0xFFEF4444),
      cardBackground: Color(0xFF1E293B),
      cardBorder: Color(0xFF334155),
      surfaceSubtle: Color(0xFF0F172A),
      textPrimary: Color(0xFFF8FAFC),
      textSecondary: Color(0xFFCBD5E1),
      textMuted: Color(0xFF64748B),
      goldAccent: Color(0xFFFBBF24),
      silverAccent: Color(0xFFCBD5E1),
      bronzeAccent: Color(0xFFD97706),
      binderBadgeBackground: Color(0xFF1E1B4B),
    );
  }

  @override
  ThemeExtension<AppThemeColors> copyWith({
    Color? profit,
    Color? loss,
    Color? cardBackground,
    Color? cardBorder,
    Color? surfaceSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? goldAccent,
    Color? silverAccent,
    Color? bronzeAccent,
    Color? binderBadgeBackground,
  }) {
    return AppThemeColors(
      profit: profit ?? this.profit,
      loss: loss ?? this.loss,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      goldAccent: goldAccent ?? this.goldAccent,
      silverAccent: silverAccent ?? this.silverAccent,
      bronzeAccent: bronzeAccent ?? this.bronzeAccent,
      binderBadgeBackground:
          binderBadgeBackground ?? this.binderBadgeBackground,
    );
  }

  @override
  ThemeExtension<AppThemeColors> lerp(
    ThemeExtension<AppThemeColors>? other,
    double t,
  ) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      profit: Color.lerp(profit, other.profit, t) ?? profit,
      loss: Color.lerp(loss, other.loss, t) ?? loss,
      cardBackground:
          Color.lerp(cardBackground, other.cardBackground, t) ?? cardBackground,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t) ?? cardBorder,
      surfaceSubtle:
          Color.lerp(surfaceSubtle, other.surfaceSubtle, t) ?? surfaceSubtle,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      goldAccent: Color.lerp(goldAccent, other.goldAccent, t) ?? goldAccent,
      silverAccent:
          Color.lerp(silverAccent, other.silverAccent, t) ?? silverAccent,
      bronzeAccent:
          Color.lerp(bronzeAccent, other.bronzeAccent, t) ?? bronzeAccent,
      binderBadgeBackground:
          Color.lerp(binderBadgeBackground, other.binderBadgeBackground, t) ??
              binderBadgeBackground,
    );
  }
}

/// Praktische BuildContext Extensions für einfachen Zugriff auf Farbwerte.
extension BuildContextThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  AppThemeColors get appColors =>
      Theme.of(this).extension<AppThemeColors>() ??
      (isDarkMode ? AppThemeColors.dark() : AppThemeColors.light());
}
