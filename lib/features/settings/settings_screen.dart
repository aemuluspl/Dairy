import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/max_width_box.dart';
import '../../data/models/nav_bar_style.dart';
import '../../state/app_state.dart';
import '../../widgets/pill_nav_bar.dart';
import '../../widgets/top_bar.dart';
import 'aliases_settings_screen.dart';
import 'data_settings_screen.dart';
import 'schedule_settings_screen.dart';
import 'settings_common.dart';
import 'update_settings_screen.dart';
import 'widget_settings_screen.dart';

/// Настройки: независимые карточки, простые пункты раскрываются на месте.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

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
    final palette = context.palette;
    final state = context.watch<AppState>();
    final strings = state.strings;

    return SafeArea(
      bottom: false,
      child: MaxWidthBox(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TopBar(title: strings.settingsTitle),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    top: 2,
                    bottom: PillNavBar.contentInset,
                  ),
                  children: <Widget>[
                    SettingsSectionLabel(strings.appearance),
                    const SizedBox(height: 8),
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
                    SettingsSectionLabel(strings.dataSection),
                    const SizedBox(height: 8),
                    SettingsCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: SettingsMenuTile(
                        icon: Icons.calendar_month_rounded,
                        title: strings.settingsSchedule,
                        subtitle: strings.settingsScheduleSubtitle,
                        onTap: () => _open(
                          context,
                          const ScheduleSettingsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SettingsCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: SettingsMenuTile(
                        icon: Icons.tag_rounded,
                        title: strings.settingsAliases,
                        subtitle: strings.settingsAliasesSubtitle,
                        onTap: () => _open(
                          context,
                          const AliasesSettingsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SettingsCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: SettingsMenuTile(
                        icon: Icons.folder_rounded,
                        title: strings.settingsData,
                        subtitle: strings.settingsDataSubtitle,
                        onTap: () => _open(
                          context,
                          const DataSettingsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SettingsCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: SettingsMenuTile(
                        icon: Icons.widgets_rounded,
                        title: strings.settingsWidget,
                        subtitle: strings.settingsWidgetSubtitle,
                        onTap: () => _open(
                          context,
                          const WidgetSettingsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SettingsCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: SettingsMenuTile(
                        icon: Icons.system_update_rounded,
                        title: strings.settingsUpdate,
                        subtitle:
                            state.updateAvailable && state.latestVersion != null
                                ? strings.updateAvailableTitle(
                                    state.latestVersion!,
                                  )
                                : strings.settingsUpdateSubtitle(state.version),
                        badge: state.updateAvailable,
                        onTap: () => _open(
                          context,
                          const UpdateSettingsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      strings.footerTitle(state.version),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
