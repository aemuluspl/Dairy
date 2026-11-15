import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
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
                                onChanged: (time) => state
                                    .setWidgetSimulatedTime(_format(time)),
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
