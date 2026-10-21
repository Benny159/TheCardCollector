import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';

/// Ein moderner, interaktiver BottomSheet zur Konfiguration von
/// Light / Dark Mode, Farb-Themes und benutzerdefinierten Primärfarben.
class ThemeSettingsSheet extends ConsumerWidget {
  const ThemeSettingsSheet({super.key});

  /// Öffnet das Theme-Einstellungsfenster als Bottom-Sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ThemeSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeNotifierProvider);
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    final theme = Theme.of(context);
    final colors = context.appColors;
    final primaryColor = themeState.primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag-Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.palette_rounded, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Design & Farbschema',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),
                      Text(
                        'Passe Dark/Light Mode & App-Farben an',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Schließen',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollbarer Inhalt
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // -------------------------------------------------------------
                // 1. ERSCHEINUNGSBILD (SYSTEM / HELL / DUNKEL)
                // -------------------------------------------------------------
                _buildSectionHeader(
                  icon: Icons.brightness_medium_rounded,
                  title: 'Erscheinungsbild',
                  subtitle: 'Wähle zwischen hellem, dunklem oder System-Modus',
                  primaryColor: primaryColor,
                  context: context,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeOptionCard(
                        context: context,
                        title: 'System',
                        subtitle: 'Automatisch',
                        icon: Icons.settings_brightness_rounded,
                        isSelected: themeState.themeMode == ThemeMode.system,
                        primaryColor: primaryColor,
                        onTap: () => themeNotifier.setThemeMode(ThemeMode.system),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildModeOptionCard(
                        context: context,
                        title: 'Hell',
                        subtitle: 'Light Mode',
                        icon: Icons.light_mode_rounded,
                        isSelected: themeState.themeMode == ThemeMode.light,
                        primaryColor: primaryColor,
                        onTap: () => themeNotifier.setThemeMode(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildModeOptionCard(
                        context: context,
                        title: 'Dunkel',
                        subtitle: 'Dark Mode',
                        icon: Icons.dark_mode_rounded,
                        isSelected: themeState.themeMode == ThemeMode.dark,
                        primaryColor: primaryColor,
                        onTap: () => themeNotifier.setThemeMode(ThemeMode.dark),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // -------------------------------------------------------------
                // 2. VORDEFINIERTE FARB-THEMES (PRESETS)
                // -------------------------------------------------------------
                _buildSectionHeader(
                  icon: Icons.color_lens_rounded,
                  title: 'Farb-Thema (Primär & Akzente)',
                  subtitle: 'Abgestimmte TCG- & Pokémon-Farbpaletten',
                  primaryColor: primaryColor,
                  context: context,
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: AppColors.presets.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.15,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final preset = AppColors.presets[index];
                    final isSelected = themeState.customPrimaryColor == null &&
                        themeState.presetId == preset.id;

                    return _buildPresetTile(
                      context: context,
                      preset: preset,
                      isSelected: isSelected,
                      onTap: () => themeNotifier.setPreset(preset.id),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // -------------------------------------------------------------
                // 3. INDIVIDUELLE FARBE (CUSTOM COLOR PICKER)
                // -------------------------------------------------------------
                _buildSectionHeader(
                  icon: Icons.brush_rounded,
                  title: 'Individuelle Primärfarbe',
                  subtitle: 'Wähle deinen ganz persönlichen Farbton',
                  primaryColor: primaryColor,
                  context: context,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: AppColors.customColorPalette.map((color) {
                    final isSelected = themeState.customPrimaryColor?.toARGB32() ==
                        color.toARGB32();

                    return InkWell(
                      onTap: () => themeNotifier.setCustomPrimaryColor(color),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? (context.isDarkMode ? Colors.white : Colors.black)
                                : Colors.transparent,
                            width: isSelected ? 3 : 0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 22)
                            : null,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // -------------------------------------------------------------
                // 4. ECHTZEIT-VORSCHAU (LIVE PREVIEW)
                // -------------------------------------------------------------
                _buildSectionHeader(
                  icon: Icons.visibility_rounded,
                  title: 'Echtzeit-Vorschau',
                  subtitle: 'So sieht dein neues Farbschema in Aktion aus',
                  primaryColor: primaryColor,
                  context: context,
                ),
                const SizedBox(height: 12),
                _buildLivePreviewCard(context, primaryColor, colors),

                const SizedBox(height: 20),

                // Zurücksetzen Button
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      themeNotifier.resetToDefault();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Theme auf Werkseinstellung zurückgesetzt.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Auf Standard zurücksetzen'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Header-Helper ---
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primaryColor,
    required BuildContext context,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Karte für ThemeMode (System/Hell/Dunkel) ---
  Widget _buildModeOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.12)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primaryColor : theme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? primaryColor : colors.textSecondary,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                  color: isSelected ? primaryColor : colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.8)
                      : colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Kachel für Farbvorgaben (Presets) ---
  Widget _buildPresetTile({
    required BuildContext context,
    required AppColorPreset preset,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? preset.primary.withValues(alpha: 0.12)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? preset.primary : theme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Farb-Kreis mit Primär & Sekundär-Kombination
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: preset.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: preset.primary.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: preset.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check, color: Colors.white, size: 18),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                preset.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? preset.primary : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Echtzeit-Vorschaukarte ---
  Widget _buildLivePreviewCard(
    BuildContext context,
    Color primaryColor,
    AppThemeColors colors,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      primaryColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.catching_pokemon,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Glurak ex #199/165',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '151 Special Illustration Rare',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.profit.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+ 14.8 %',
                  style: TextStyle(
                    color: colors.profit,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Zum Inventar'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
