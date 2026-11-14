import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../state/app_state.dart';
import 'settings_common.dart';

/// Заглушка под будущие настройки Android-виджета.
class WidgetSettingsScreen extends StatelessWidget {
  const WidgetSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final strings = context.watch<AppState>().strings;

    return SettingsSubScaffold(
      title: strings.settingsWidget,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 2, bottom: 24),
        children: <Widget>[
          SettingsCard(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
            child: Column(
              children: <Widget>[
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.widgets_rounded,
                    size: 26,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  strings.widgetStubTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.widgetStubMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
