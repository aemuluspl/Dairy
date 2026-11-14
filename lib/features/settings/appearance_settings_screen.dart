import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../state/app_state.dart';
import 'settings_common.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    final strings = state.strings;

    return SettingsSubScaffold(
      title: strings.settingsAppearance,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 2, bottom: 24),
        children: <Widget>[
          SettingsSectionLabel(strings.appearance),
          const SizedBox(height: 8),
          SettingsCard(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _ThemeOption(
                      mode: ThemeMode.light,
                      current: state.themeMode,
                      icon: Icons.light_mode_rounded,
                      label: strings.themeLight,
                      onSelect: state.setThemeMode,
                    ),
                    const SizedBox(width: 6),
                    _ThemeOption(
                      mode: ThemeMode.dark,
                      current: state.themeMode,
                      icon: Icons.dark_mode_rounded,
                      label: strings.themeDark,
                      onSelect: state.setThemeMode,
                    ),
                    const SizedBox(width: 6),
                    _ThemeOption(
                      mode: ThemeMode.system,
                      current: state.themeMode,
                      icon: Icons.brightness_auto_rounded,
                      label: strings.themeSystem,
                      onSelect: state.setThemeMode,
                    ),
                  ],
                ),
                Divider(height: 14, color: palette.border),
                SettingsSwitchRow(
                  icon: state.newIconLines
                      ? Icons.draw_rounded
                      : Icons.edit_rounded,
                  title: strings.newIconTitle,
                  subtitle: strings.newIconHint,
                  value: state.newIconLines,
                  onChanged: state.setNewIconLines,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.current,
    required this.icon,
    required this.label,
    required this.onSelect,
  });

  final ThemeMode mode;
  final ThemeMode current;
  final IconData icon;
  final String label;
  final Future<void> Function(ThemeMode mode) onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final selected = mode == current;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelect(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? palette.accent : palette.chip,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Column(
            children: <Widget>[
              Icon(
                icon,
                size: 20,
                color: selected ? palette.onAccent : palette.textSecondary,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: selected ? palette.onAccent : palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
