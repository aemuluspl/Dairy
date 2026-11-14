import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_text.dart';
import '../../core/utils/max_width_box.dart';
import '../../data/models/lesson.dart';
import '../../state/app_state.dart';
import '../../widgets/soft_chip.dart';
import '../../widgets/time_wheel_picker.dart';
import '../../widgets/top_bar.dart';

/// Редактор расписания: порядок уроков, время, кабинет.
class ScheduleEditScreen extends StatefulWidget {
  const ScheduleEditScreen({super.key});

  @override
  State<ScheduleEditScreen> createState() => _ScheduleEditScreenState();
}

class _ScheduleEditScreenState extends State<ScheduleEditScreen> {
  int _day = DateTime.monday;

  static const List<({String start, String end})> _slots =
      <({String start, String end})>[
    (start: '08:00', end: '08:40'),
    (start: '08:50', end: '09:30'),
    (start: '09:45', end: '10:25'),
    (start: '10:40', end: '11:20'),
    (start: '11:35', end: '12:15'),
    (start: '12:30', end: '13:10'),
    (start: '13:25', end: '14:05'),
  ];

  Future<void> _persist(List<Lesson> lessons) async {
    await context.read<AppState>().saveScheduleDay(_day, lessons);
  }

  Future<void> _editLesson(
    List<Lesson> lessons, {
    Lesson? lesson,
    int? index,
  }) async {
    final strings = context.read<AppState>().strings;
    final result = await showDialog<_LessonResult>(
      context: context,
      builder: (_) => _LessonDialog(
        strings: strings,
        initial: lesson,
        fallback: _slots[(index ?? lessons.length) % _slots.length],
      ),
    );
    if (result == null) return;

    if (result.deleted && index != null) {
      final next = List<Lesson>.from(lessons)..removeAt(index);
      await _persist(next);
      return;
    }

    final edited = result.lesson;
    if (edited == null) return;
    final next = List<Lesson>.from(lessons);
    if (index == null) {
      next.add(edited);
    } else {
      next[index] = edited;
    }
    await _persist(next);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    final strings = state.strings;
    final lessons = state.lessonsFor(_day);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: MaxWidthBox(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TopBar(
                  title: strings.editTitle,
                  leading: RoundIconButton(
                    icon: Icons.close_rounded,
                    tooltip: strings.close,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  trailing: RoundIconButton(
                    icon: Icons.check_rounded,
                    tooltip: strings.done,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final day = DateTime.monday + index;
                      return SoftChip(
                        label: weekdayShort(day, english: strings.isEnglish),
                        accent: day == _day,
                        onTap: () => setState(() => _day = day),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                _DaysOffCard(state: state, strings: strings),
                const SizedBox(height: 10),
                Expanded(
                  child: ReorderableListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 6, bottom: 12),
                    buildDefaultDragHandles: false,
                    // Встроенный «подъём» рисует прямоугольную подложку с тенью —
                    // у скруглённого урока торчали углы. Оставляем только
                    // лёгкое увеличение, без прямоугольника.
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final t = Curves.easeOut.transform(animation.value);
                          return Transform.scale(
                            scale: 1 + 0.02 * t,
                            child: Material(
                              type: MaterialType.transparency,
                              child: child,
                            ),
                          );
                        },
                        child: child,
                      );
                    },
                    itemCount: lessons.length,
                    onReorderItem: (oldIndex, newIndex) {
                      // onReorderItem уже учитывает сдвиг после удаления.
                      final next = List<Lesson>.from(lessons);
                      final item = next.removeAt(oldIndex);
                      next.insert(newIndex, item);
                      _persist(next);
                    },
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      return Padding(
                        key: ObjectKey(lesson),
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _EditableLessonRow(
                          index: index,
                          lesson: lesson,
                          strings: strings,
                          showRoom: state.showRooms,
                          onTap: () => _editLesson(lessons,
                              lesson: lesson, index: index),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, top: 4),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => _editLesson(lessons),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(strings.addLesson),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditableLessonRow extends StatelessWidget {
  const _EditableLessonRow({
    required this.index,
    required this.lesson,
    required this.strings,
    required this.showRoom,
    required this.onTap,
  });

  final int index;
  final Lesson lesson;
  final Strings strings;
  final bool showRoom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            child: Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        lesson.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        <String>[
                          '${lesson.start}–${lesson.end}',
                          if (showRoom &&
                              lesson.room != null &&
                              lesson.room!.isNotEmpty)
                            lesson.room!,
                        ].join(' · '),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      size: 20,
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonResult {
  const _LessonResult({this.lesson, this.deleted = false});

  final Lesson? lesson;
  final bool deleted;
}

class _LessonDialog extends StatefulWidget {
  const _LessonDialog({
    required this.strings,
    required this.initial,
    required this.fallback,
  });

  final Strings strings;
  final Lesson? initial;
  final ({String start, String end}) fallback;

  @override
  State<_LessonDialog> createState() => _LessonDialogState();
}

class _LessonDialogState extends State<_LessonDialog> {
  late final TextEditingController _subject;
  late final TextEditingController _room;
  late String _startValue;
  late String _endValue;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _subject = TextEditingController(text: initial?.subject ?? '');
    _room = TextEditingController(text: initial?.room ?? '');
    _startValue = initial?.start ?? widget.fallback.start;
    _endValue = initial?.end ?? widget.fallback.end;
  }

  @override
  void dispose() {
    _subject.dispose();
    _room.dispose();
    super.dispose();
  }

  String _addMinutes(String value, int minutes) {
    final time = parseClock(value);
    return formatClock((
      hour: (time.hour + (time.minute + minutes) ~/ 60) % 24,
      minute: (time.minute + minutes) % 60,
    ));
  }

  Future<void> _pickTime({required bool start}) async {
    final strings = context.read<AppState>().strings;
    final picked = await showTimeWheelPicker(
      context,
      title: start ? strings.timeStartTitle : strings.timeEndTitle,
      initial: start ? _startValue : _endValue,
      strings: strings,
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (start) {
        // Если конец ещё не правили вручную — сдвигаем его на 40 минут.
        if (_endValue == _addMinutes(_startValue, 40)) {
          _endValue = _addMinutes(picked, 40);
        }
        _startValue = picked;
      } else {
        _endValue = picked;
      }
    });
  }

  void _apply() {
    final subject = _subject.text.trim();
    if (subject.isEmpty) return;
    Navigator.of(context).pop(
      _LessonResult(
        lesson: Lesson(
          subject: subject,
          start: _startValue,
          end: _endValue,
          room: _room.text.trim().isEmpty ? null : _room.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final strings = widget.strings;
    final editing = widget.initial != null;

    return AlertDialog(
      backgroundColor: palette.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(
        editing ? strings.editLesson : strings.addLesson,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Field(
              controller: _subject,
              label: strings.lessonSubject,
              autofocus: true,
            ),
            const SizedBox(height: 10),
            _Field(controller: _room, label: strings.lessonRoom),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: _TimeField(
                    value: _startValue,
                    label: strings.lessonStart,
                    onTap: () => _pickTime(start: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeField(
                    value: _endValue,
                    label: strings.lessonEnd,
                    onTap: () => _pickTime(start: false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        if (editing)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(const _LessonResult(deleted: true)),
            style: TextButton.styleFrom(foregroundColor: palette.danger),
            child: Text(strings.delete),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(onPressed: _apply, child: Text(strings.save)),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.value,
    required this.label,
    required this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.schedule_rounded,
                size: 18,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Компактная карточка «каникулы и выходные» в редакторе расписания.
class _DaysOffCard extends StatelessWidget {
  const _DaysOffCard({required this.state, required this.strings});

  final AppState state;
  final Strings strings;

  Future<void> _addHolidays(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3, 12, 31),
      initialDateRange: DateTimeRange(start: now, end: now),
      helpText: strings.addHolidays,
      cancelText: strings.cancel,
      saveText: strings.save,
      locale: strings.isEnglish
          ? const Locale('en', 'US')
          : const Locale('ru', 'RU'),
    );
    if (range == null) return;
    await state.addHoliday(range.start, range.end);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final holidays = state.holidays;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 10, 10),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.weekend_rounded,
                size: 18,
                color: palette.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings.saturdayOffTitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      strings.saturdayOffHint,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.saturdayOff,
                onChanged: state.setSaturdayOff,
                activeThumbColor: palette.onAccent,
                activeTrackColor: palette.accent,
              ),
            ],
          ),
          Divider(height: 12, color: palette.border),
          Row(
            children: <Widget>[
              Icon(
                Icons.beach_access_rounded,
                size: 18,
                color: palette.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings.holidaysTitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      strings.holidaysHint,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _addHolidays(context),
                child: Text(strings.addHolidays),
              ),
            ],
          ),
          if (holidays.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4, left: 26),
              child: Text(
                strings.noHolidays,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: palette.textMuted,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final period in holidays)
                    _HolidayChip(
                      label: strings.holidayPeriod(
                        formatDayMonth(
                          period.start,
                          english: strings.isEnglish,
                        ),
                        formatDayMonth(period.end, english: strings.isEnglish),
                      ),
                      onRemove: () => state.removeHoliday(period),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HolidayChip extends StatelessWidget {
  const _HolidayChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextField(
      controller: controller,
      autofocus: autofocus,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: palette.textMuted,
        ),
        filled: true,
        fillColor: palette.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.accent),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}
