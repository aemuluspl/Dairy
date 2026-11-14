import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../state/app_state.dart';
import 'settings_common.dart';

class ScheduleSettingsScreen extends StatelessWidget {
  const ScheduleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    final strings = state.strings;

    return SettingsSubScaffold(
      title: strings.settingsSchedule,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 2, bottom: 24),
        children: <Widget>[
          SettingsSectionLabel(strings.scheduleSection),
          const SizedBox(height: 8),
          SettingsCard(
            padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
            child: Column(
              children: <Widget>[
                SettingsSwitchRow(
                  icon: Icons.meeting_room_outlined,
                  title: strings.showRooms,
                  subtitle: strings.showRoomsHint,
                  value: state.showRooms,
                  onChanged: state.setShowRooms,
                ),
                Divider(height: 1, color: palette.border),
                SettingsSwitchRow(
                  icon: Icons.weekend_rounded,
                  title: strings.saturdayOffTitle,
                  subtitle: strings.saturdayOffHint,
                  value: state.saturdayOff,
                  onChanged: state.setSaturdayOff,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
