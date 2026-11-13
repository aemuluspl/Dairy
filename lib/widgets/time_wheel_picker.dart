import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/i18n/app_strings.dart';
import '../core/theme/app_palette.dart';

/// Время урока в формате «ЧЧ:ММ».
typedef ClockTime = ({int hour, int minute});

ClockTime parseClock(String value, {int fallbackHour = 8}) {
  final parts = value.split(':');
  final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
  return (
    hour: (hour ?? fallbackHour).clamp(0, 23),
    minute: (minute ?? 0).clamp(0, 59),
  );
}

String formatClock(ClockTime time) => '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

/// Барабанный выбор времени в стиле iOS: слева часы, справа минуты.
Future<String?> showTimeWheelPicker(
  BuildContext context, {
  required String title,
  required String initial,
  required Strings strings,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _TimeWheelSheet(
      title: title,
      initial: initial,
      strings: strings,
    ),
  );
}

class _TimeWheelSheet extends StatefulWidget {
  const _TimeWheelSheet({
    required this.title,
    required this.initial,
    required this.strings,
  });

  final String title;
  final String initial;
  final Strings strings;

  @override
  State<_TimeWheelSheet> createState() => _TimeWheelSheetState();
}

class _TimeWheelSheetState extends State<_TimeWheelSheet> {
  late final ClockTime _startValue = parseClock(widget.initial);
  late int _hour = _startValue.hour;
  late int _minute = _startValue.minute;

  late final FixedExtentScrollController _hourController =
      FixedExtentScrollController(initialItem: _hour);
  late final FixedExtentScrollController _minuteController =
      FixedExtentScrollController(initialItem: _minute);

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final strings = widget.strings;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 190,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _TimeWheel(
                      controller: _hourController,
                      count: 24,
                      selected: _hour,
                      label: strings.timeHours,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        setState(() => _hour = value);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        ':',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                    _TimeWheel(
                      controller: _minuteController,
                      count: 60,
                      selected: _minute,
                      label: strings.timeMinutes,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        setState(() => _minute = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: palette.border),
                          foregroundColor: palette.textSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(strings.cancel),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(
                          formatClock((hour: _hour, minute: _minute)),
                        ),
                        child: Text(strings.save),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeWheel extends StatelessWidget {
  const _TimeWheel({
    required this.controller,
    required this.count,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final int count;
  final int selected;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: palette.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 96,
          height: 158,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              IgnorePointer(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 46,
                physics: const FixedExtentScrollPhysics(),
                diameterRatio: 1.5,
                perspective: 0.003,
                onSelectedItemChanged: onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: count,
                  builder: (context, index) {
                    final active = index == selected;
                    return Center(
                      child: Text(
                        index.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: active ? 28 : 19,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color:
                              active ? palette.textPrimary : palette.textMuted,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
