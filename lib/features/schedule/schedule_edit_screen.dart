import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_text.dart';
import '../../core/utils/max_width_box.dart';
import '../../data/models/lesson.dart';
import '../../state/app_state.dart';
import '../../widgets/soft_chip.dart';
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
                Text(
                  strings.reorderHint,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
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
  late final TextEditingController _start;
  late final TextEditingController _end;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _subject = TextEditingController(text: initial?.subject ?? '');
    _room = TextEditingController(text: initial?.room ?? '');
    _start =
        TextEditingController(text: initial?.start ?? widget.fallback.start);
    _end = TextEditingController(text: initial?.end ?? widget.fallback.end);
  }

  @override
  void dispose() {
    _subject.dispose();
    _room.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  void _apply() {
    final subject = _subject.text.trim();
    if (subject.isEmpty) return;
    Navigator.of(context).pop(
      _LessonResult(
        lesson: Lesson(
          subject: subject,
          start: _start.text.trim().isEmpty
              ? widget.fallback.start
              : _start.text.trim(),
          end:
              _end.text.trim().isEmpty ? widget.fallback.end : _end.text.trim(),
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
                  child: _Field(
                    controller: _start,
                    label: strings.lessonStart,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Field(controller: _end, label: strings.lessonEnd),
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
