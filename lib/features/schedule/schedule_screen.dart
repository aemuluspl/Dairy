import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_text.dart';
import '../../core/utils/school_day.dart';
import '../../core/utils/max_width_box.dart';
import '../../data/models/lesson.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pill_nav_bar.dart';
import '../../widgets/soft_chip.dart';
import '../../widgets/top_bar.dart';
import 'schedule_edit_screen.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  void _openEditor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ScheduleEditScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Даты недели и бейджи «сегодня/завтра» пересчитываются в полночь,
    // даже если вкладка открыта всю ночь.
    return _WeekTicker(builder: _buildContent);
  }

  Widget _buildContent(BuildContext context) {
    final state = context.watch<AppState>();
    final strings = state.strings;
    final now = DateTime.now();
    final marks = resolveDayMarks(
      now,
      state.schedule,
      saturdayOff: state.saturdayOff,
    );
    final live = resolveLiveStatus(
      now,
      state.schedule,
      saturdayOff: state.saturdayOff,
    );
    // Даты текущей недели: понедельник + смещение дня.
    final weekStart =
        DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final days = <int>[
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
    ];
    final totalLessons = days.fold<int>(
      0,
      (sum, day) =>
          sum +
          (day == DateTime.saturday && state.saturdayOff
              ? 0
              : state.lessonsFor(day).length),
    );
    // Суббота остаётся в списке даже выходным, поэтому пустое состояние
    // показываем только когда уроков нет ни в один из дней.
    final hasAnyLessons = days.any(
      (day) => state.lessonsFor(day).isNotEmpty,
    );

    return SafeArea(
      bottom: false,
      child: MaxWidthBox(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TopBar(
                title: strings.scheduleTitle,
                trailing: RoundIconButton(
                  icon: Icons.edit_rounded,
                  tooltip: strings.editSchedule,
                  onTap: () => _openEditor(context),
                ),
              ),
              const SizedBox(height: 10),
              if (!hasAnyLessons)
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: EmptyState(
                          icon: Icons.calendar_month_rounded,
                          title: strings.scheduleEmptyTitle,
                          message: strings.scheduleEmptyMessage,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: () => _openEditor(context),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: Text(strings.addLesson),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: 2,
                      bottom: PillNavBar.contentInset,
                    ),
                    children: <Widget>[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          SoftChip(
                            label: strings.lessonsCount(totalLessons),
                            icon: Icons.schedule_rounded,
                          ),
                          ..._liveChips(live, strings),
                          if (state.calendar.isHoliday(now))
                            SoftChip(
                              label: strings.holidaysNow,
                              icon: Icons.beach_access_rounded,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (var day = DateTime.monday;
                          day <= DateTime.sunday;
                          day++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DayCard(
                            day: day,
                            date: weekStart.add(Duration(days: day - 1)),
                            lessons: state.lessonsFor(day),
                            isToday: day == marks.today,
                            isTomorrow: day == marks.tomorrow,
                            showRooms: state.showRooms,
                            saturdayOff: state.saturdayOff,
                            strings: strings,
                            initiallyExpanded: day ==
                                (marks.today ??
                                    marks.tomorrow ??
                                    DateTime.monday),
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

/// Перерисовывает вкладку в полночь: даты недели и бейджи «сегодня/завтра»
/// не должны «застывать» на вчерашнем дне.
class _WeekTicker extends StatefulWidget {
  const _WeekTicker({required this.builder});

  final WidgetBuilder builder;

  @override
  State<_WeekTicker> createState() => _WeekTickerState();
}

class _WeekTickerState extends State<_WeekTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _timer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(nextMidnight.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleMidnight();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

List<Widget> _liveChips(LiveStatus status, Strings strings) {
  switch (status.kind) {
    case LiveStatusKind.inLesson:
      final lesson = status.lesson;
      final next = status.nextLesson;
      if (lesson == null) return const <Widget>[];
      return <Widget>[
        SoftChip(
          label: strings.statusInLesson(
            lesson.subject,
            lesson.start,
            lesson.end,
          ),
          icon: Icons.play_circle_fill_rounded,
          accent: true,
        ),
        if (next != null)
          SoftChip(
            label: strings.statusNextLesson(
              next.subject,
              next.start,
              next.end,
            ),
            icon: Icons.skip_next_rounded,
          ),
      ];
    case LiveStatusKind.onBreak:
      final next = status.nextLesson;
      return <Widget>[
        SoftChip(
          label: next == null
              ? strings.statusBreak(status.time ?? '')
              : strings.statusBreakNext(
                  status.time ?? next.start,
                  next.subject,
                ),
          icon: Icons.free_breakfast_rounded,
          accent: true,
        ),
      ];
    case LiveStatusKind.beforeSchool:
      return <Widget>[
        SoftChip(
          label: strings.statusFirstLesson(status.time ?? ''),
          icon: Icons.backpack_rounded,
          accent: true,
        ),
      ];
    case LiveStatusKind.tomorrow:
      return <Widget>[
        SoftChip(
          label: strings.statusTomorrow(status.lessonCount ?? 0),
          icon: Icons.event_rounded,
          accent: true,
        ),
      ];
    case LiveStatusKind.nextDay:
      return <Widget>[
        SoftChip(
          label: strings.statusNextDay(
            capitalizeFirst(
              weekdayFull(
                status.day ?? DateTime.monday,
                english: strings.isEnglish,
              ),
            ),
          ),
          icon: Icons.fast_forward_rounded,
          accent: true,
        ),
      ];
  }
}

class _DayCard extends StatefulWidget {
  const _DayCard({
    required this.day,
    required this.date,
    required this.lessons,
    required this.isToday,
    required this.isTomorrow,
    required this.initiallyExpanded,
    required this.showRooms,
    required this.saturdayOff,
    required this.strings,
  });

  final int day;
  final DateTime date;
  final List<Lesson> lessons;
  final bool isToday;
  final bool isTomorrow;
  final bool initiallyExpanded;
  final bool showRooms;
  final bool saturdayOff;
  final Strings strings;

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  late bool _expanded = widget.initiallyExpanded && !_isConfiguredDayOff;

  bool get _isConfiguredDayOff =>
      widget.day == DateTime.sunday ||
      (widget.saturdayOff && widget.day == DateTime.saturday);

  bool get _dayOff => _isConfiguredDayOff;

  @override
  void didUpdateWidget(covariant _DayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Субботу только что сделали выходным — сворачиваем карточку, даже если
    // пользователь успел её раскрыть.
    if (!oldWidget.saturdayOff &&
        widget.saturdayOff &&
        widget.day == DateTime.saturday &&
        _expanded) {
      setState(() => _expanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final highlight = widget.isToday;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: highlight
              ? palette.accent.withValues(alpha: 0.3)
              : palette.border,
          width: highlight ? 1.4 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.24 : 0.03),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap:
                  _dayOff ? null : () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: <Widget>[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: highlight ? palette.accent : palette.accentSoft,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        weekdayShort(
                          widget.day,
                          english: widget.strings.isEnglish,
                        ).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: highlight
                              ? palette.onAccent
                              : palette.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  capitalizeFirst(
                                    weekdayFull(
                                      widget.day,
                                      english: widget.strings.isEnglish,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                              if (highlight || widget.isTomorrow) ...<Widget>[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: highlight
                                        ? palette.accentSoft
                                        : palette.chip,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    highlight
                                        ? widget.strings.todayBadge
                                        : widget.strings.tomorrowBadge,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: highlight
                                          ? palette.textPrimary
                                          : palette.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${formatDayMonth(widget.date, english: widget.strings.isEnglish)}'
                            ' · ${_dayOff ? widget.strings.dayOff : widget.strings.lessonsCount(widget.lessons.length)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_dayOff)
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOut,
                        child: Icon(
                          Icons.expand_more_rounded,
                          size: 22,
                          color: palette.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded && !_dayOff
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Divider(
                        height: 1,
                        indent: 14,
                        endIndent: 14,
                        color: palette.border,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                        child: Column(
                          children: <Widget>[
                            if (widget.lessons.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  widget.strings.noLessons,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ),
                            for (var index = 0;
                                index < widget.lessons.length;
                                index++)
                              _LessonRow(
                                lesson: widget.lessons[index],
                                showRoom: widget.showRooms,
                                showDivider: index != widget.lessons.length - 1,
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.lesson,
    required this.showDivider,
    required this.showRoom,
  });

  final Lesson lesson;
  final bool showDivider;
  final bool showRoom;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasRoom = showRoom && lesson.room != null && lesson.room!.isNotEmpty;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      lesson.start,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      lesson.end,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 3,
                height: 32,
                margin: const EdgeInsets.only(right: 11, top: 1),
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      lesson.subject,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    if (hasRoom) ...<Widget>[
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.meeting_room_outlined,
                            size: 11,
                            color: palette.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            lesson.room!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: palette.border.withValues(alpha: 0.7),
          ),
      ],
    );
  }
}
