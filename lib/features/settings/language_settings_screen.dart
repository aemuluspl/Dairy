import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../state/app_state.dart';
import 'settings_common.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    final strings = state.strings;

    return SettingsSubScaffold(
      title: strings.settingsLanguage,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 2, bottom: 24),
        children: <Widget>[
          SettingsSectionLabel(strings.languageSection),
          const SizedBox(height: 8),
          SettingsCard(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: <Widget>[
                for (final language in AppLanguage.values) ...<Widget>[
                  if (language != AppLanguage.values.first)
                    const SizedBox(width: 6),
                  Expanded(
                    child: _LanguageOption(
                      language: language,
                      current: state.language,
                      title: language == AppLanguage.mixed
                          ? strings.languageMixed
                          : strings.languageEnglish,
                      hint: language == AppLanguage.mixed
                          ? strings.languageMixedHint
                          : strings.languageEnglishHint,
                      onSelect: state.setLanguage,
                      palette: palette,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.language,
    required this.current,
    required this.title,
    required this.hint,
    required this.onSelect,
    required this.palette,
  });

  final AppLanguage language;
  final AppLanguage current;
  final String title;
  final String hint;
  final Future<void> Function(AppLanguage language) onSelect;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final selected = language == current;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelect(language),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? palette.accent : palette.chip,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Column(
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: selected ? palette.onAccent : palette.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: selected ? palette.onAccent : palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
