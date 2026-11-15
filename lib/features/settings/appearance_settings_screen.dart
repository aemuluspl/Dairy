import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../data/models/nav_bar_style.dart';
import '../../state/app_state.dart';
import 'settings_common.dart';
import 'widget_settings_screen.dart';

/// Оформление: тема, язык, стиль навигации и настройки виджета.
class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  String _themeLabel(Strings strings, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => strings.themeLight,
      ThemeMode.dark => strings.themeDark,
      ThemeMode.system => strings.themeSystem,
    };
  }

  String _languageLabel(Strings strings, AppLanguage language) {
    return language == AppLanguage.english
        ? strings.languageEnglish
        : strings.languageMixed;
  }

  String _navBarLabel(Strings strings, NavBarStyle style) {
    return style == NavBarStyle.liquidGlass
        ? strings.navBarGlass
        : strings.navBarClassic;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final strings = state.strings;

    return SettingsSubScaffold(
      title: strings.settingsAppearance,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 2, bottom: 24),
        children: <Widget>[
          SettingsExpandableCard(
            icon: Icons.brightness_6_rounded,
            title: strings.themeTitle,
            value: _themeLabel(strings, state.themeMode),
            child: SettingsChoiceRow<ThemeMode>(
              selected: state.themeMode,
              onSelect: state.setThemeMode,
              options: <SettingsChoice<ThemeMode>>[
                SettingsChoice<ThemeMode>(
                  value: ThemeMode.light,
                  label: strings.themeLight,
                  icon: Icons.light_mode_rounded,
                ),
                SettingsChoice<ThemeMode>(
                  value: ThemeMode.dark,
                  label: strings.themeDark,
                  icon: Icons.dark_mode_rounded,
                ),
                SettingsChoice<ThemeMode>(
                  value: ThemeMode.system,
                  label: strings.themeSystem,
                  icon: Icons.brightness_auto_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SettingsExpandableCard(
            icon: Icons.translate_rounded,
            title: strings.settingsLanguage,
            value: _languageLabel(strings, state.language),
            child: SettingsChoiceRow<AppLanguage>(
              selected: state.language,
              onSelect: state.setLanguage,
              options: <SettingsChoice<AppLanguage>>[
                SettingsChoice<AppLanguage>(
                  value: AppLanguage.mixed,
                  label: strings.languageMixed,
                ),
                SettingsChoice<AppLanguage>(
                  value: AppLanguage.english,
                  label: strings.languageEnglish,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SettingsExpandableCard(
            icon: Icons.blur_on_rounded,
            title: strings.navBarTitle,
            value: _navBarLabel(strings, state.navBarStyle),
            child: SettingsChoiceRow<NavBarStyle>(
              selected: state.navBarStyle,
              onSelect: state.setNavBarStyle,
              options: <SettingsChoice<NavBarStyle>>[
                SettingsChoice<NavBarStyle>(
                  value: NavBarStyle.classic,
                  label: strings.navBarClassic,
                  icon: Icons.rounded_corner_rounded,
                ),
                SettingsChoice<NavBarStyle>(
                  value: NavBarStyle.liquidGlass,
                  label: strings.navBarGlass,
                  icon: Icons.blur_on_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SettingsSectionLabel(strings.widgetSection),
          const SizedBox(height: 8),
          SettingsCard(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: SettingsMenuTile(
              icon: Icons.widgets_rounded,
              title: strings.settingsWidget,
              subtitle: strings.settingsWidgetSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const WidgetSettingsScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
