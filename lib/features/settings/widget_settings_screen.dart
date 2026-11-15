import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/date_text.dart';
import '../../state/app_state.dart';
import 'settings_common.dart';

/// Настройки Android-виджета. Симуляция времени — отладочный инструмент:
/// она подменяет системные часы внутри нативного виджета.
class WidgetSettingsScreen extends StatelessWidget {
  const WidgetSettingsScreen({super.key});

  static String _format(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  static TimeOfDay? _parse(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) return null;
    return TimeOfDay(hour: hours, minute: minutes);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    final strings = state.strings;
    final simulated = _parse(state.widgetSimulatedTime);

    return SettingsSubScaffold(
      title: strings.settingsWidget,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 2, bottom: 24),
        children: <Widget>[
          SettingsCard(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Column(
              children: <Widget>[
                SettingsSwitchRow(
                  icon: Icons.schedule_rounded,
                  title: strings.widgetSimulationTitle,
                  subtitle: strings.widgetSimulationHint,
                  value: simulated != null,
                  onChanged: (value) => state.setWidgetSimulatedTime(
                    value ? _format(TimeOfDay.now()) : null,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: simulated == null
                      ? const SizedBox(width: double.infinity, height: 0)
                      : Column(
                          children: <Widget>[
                            Divider(height: 16, color: palette.border),
                            SizedBox(
                              height: 168,
                              child: _TimeDrum(
                                hour: simulated.hour,
                                minute: simulated.minute,
                                onChanged: (time) =>
                                    state.setWidgetSimulatedTime(_format(time)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () =>
                                    state.setWidgetSimulatedTime(null),
                                child: Text(
                                  strings.widgetSimulationReset,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SettingsCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: palette.accentSoft,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.today_rounded,
                        size: 19,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            strings.widgetWeekdayTitle,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strings.widgetWeekdayHint,
                            style: TextStyle(
                              fontSize: 10.5,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: palette.chip,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      isDense: true,
                      value: state.widgetSimulatedWeekday ?? 0,
                      borderRadius: BorderRadius.circular(16),
                      dropdownColor: palette.card,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      icon: Icon(
                        Icons.expand_more_rounded,
                        size: 20,
                        color: palette.textMuted,
                      ),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                      items: <DropdownMenuItem<int>>[
                        DropdownMenuItem<int>(
                          value: 0,
                          child: Text(strings.widgetWeekdaySystem),
                        ),
                        for (var day = DateTime.monday;
                            day <= DateTime.sunday;
                            day++)
                          DropdownMenuItem<int>(
                            value: day,
                            child: Text(
                              capitalizeFirst(
                                weekdayFull(day, english: strings.isEnglish),
                              ),
                            ),
                          ),
                      ],
                      onChanged: (value) => state.setWidgetSimulatedWeekday(
                        value == 0 ? null : value,
                      ),
                    ),
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

/// iOS-барабан на 24 часа. Держит собственное значение, чтобы плавная
/// прокрутка не сбрасывалась при перестроении экрана.
class _TimeDrum extends StatefulWidget {
  const _TimeDrum({
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  final int hour;
  final int minute;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  State<_TimeDrum> createState() => _TimeDrumState();
}

class _TimeDrumState extends State<_TimeDrum> {
  late DateTime _value = DateTime(2020, 1, 1, widget.hour, widget.minute);

  @override
  void didUpdateWidget(covariant _TimeDrum oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hour == _value.hour && widget.minute == _value.minute) return;
    _value = DateTime(2020, 1, 1, widget.hour, widget.minute);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoDatePicker(
      mode: CupertinoDatePickerMode.time,
      use24hFormat: true,
      initialDateTime: _value,
      onDateTimeChanged: (value) {
        if (value.hour == _value.hour && value.minute == _value.minute) return;
        setState(() => _value = value);
        widget.onChanged(TimeOfDay(hour: value.hour, minute: value.minute));
      },
    );
  }
}
