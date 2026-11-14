import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/max_width_box.dart';
import '../../state/app_state.dart';
import '../../widgets/pill_nav_bar.dart';
import '../../widgets/top_bar.dart';
import 'aliases_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'data_settings_screen.dart';
import 'language_settings_screen.dart';
import 'schedule_settings_screen.dart';
import 'settings_common.dart';
import 'update_settings_screen.dart';
import 'widget_settings_screen.dart';

/// Главный экран настроек: только пункты меню, весь функционал — внутри.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
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
                    SettingsCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Column(
                        children: <Widget>[
                          SettingsMenuTile(
                            icon: Icons.palette_rounded,
                            title: strings.settingsAppearance,
                            subtitle: strings.settingsAppearanceSubtitle,
                            onTap: () => _open(
                              context,
                              const AppearanceSettingsScreen(),
                            ),
                          ),
                          Divider(height: 1, color: palette.border),
                          SettingsMenuTile(
                            icon: Icons.translate_rounded,
                            title: strings.settingsLanguage,
                            subtitle: strings.settingsLanguageSubtitle,
                            onTap: () => _open(
                              context,
                              const LanguageSettingsScreen(),
                            ),
                          ),
                          Divider(height: 1, color: palette.border),
                          SettingsMenuTile(
                            icon: Icons.calendar_month_rounded,
                            title: strings.settingsSchedule,
                            subtitle: strings.settingsScheduleSubtitle,
                            onTap: () => _open(
                              context,
                              const ScheduleSettingsScreen(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SettingsSectionLabel(strings.aliasesSection),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 18),
                    SettingsSectionLabel(strings.dataSection),
                    const SizedBox(height: 8),
                    SettingsCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Column(
                        children: <Widget>[
                          SettingsMenuTile(
                            icon: Icons.folder_rounded,
                            title: strings.settingsData,
                            subtitle: strings.settingsDataSubtitle,
                            onTap: () => _open(
                              context,
                              const DataSettingsScreen(),
                            ),
                          ),
                          Divider(height: 1, color: palette.border),
                          SettingsMenuTile(
                            icon: Icons.widgets_rounded,
                            title: strings.settingsWidget,
                            subtitle: strings.settingsWidgetSubtitle,
                            onTap: () => _open(
                              context,
                              const WidgetSettingsScreen(),
                            ),
                          ),
                        ],
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
