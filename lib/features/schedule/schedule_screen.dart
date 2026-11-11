import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_text.dart';
import '../../core/utils/max_width_box.dart';
import '../../data/models/lesson.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
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
    final palette = context.palette;
    final state = context.watch<AppState>();
    final strings = state.strings;
    final now = DateTime.now();
    final today = now.weekday;
    final totalLessons = <int>[
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
    ].fold<int>(0, (sum, day) => sum + state.lessonsFor(day).length);

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
              if (totalLessons == 0)
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
                    padding: const EdgeInsets.only(top: 2, bottom: 20),
                    children: <Widget>[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          SoftChip(
                            label: strings.weekRange,
                            icon: Icons.calendar_view_week_rounded,
                          ),
                          SoftChip(
                            label: strings.lessonsCount(totalLessons),
                            icon: Icons.schedule_rounded,
                          ),
                          SoftChip(
                            label: strings.classLabel,
                            icon: Icons.groups_rounded,
                          ),
                          if (today >= DateTime.monday &&
                              today <= DateTime.saturday)
                            SoftChip(
                              label: strings.todayChip(
                                weekdayShort(
                                  today,
                                  english: strings.isEnglish,
                                ),
                              ),
                              icon: Icons.bolt_rounded,
                              accent: true,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (var day = DateTime.monday;
                          day <= DateTime.saturday;
                          day++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DayCard(
                            day: day,
                            lessons: state.lessonsFor(day),
                            isToday: day == today,
                            showRooms: state.showRooms,
                            strings: strings,
                            initiallyExpanded: day ==
                                (today <= DateTime.saturday
                                    ? today
                                    : DateTime.monday),
                          ),
                        ),
                      const SizedBox(height: 4),
                      _AliasInfoCard(
                        aliases: state.aliases,
                        strings: strings,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.scheduleStorageNote,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
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
        ),
      ),
    );
  }
}

class _DayCard extends StatefulWidget {
  const _DayCard({
    required this.day,
    required this.lessons,
    required this.isToday,
    required this.initiallyExpanded,
    required this.showRooms,
    required this.strings,
  });

  final int day;
  final List<Lesson> lessons;
  final bool isToday;
  final bool initiallyExpanded;
  final bool showRooms;
  final Strings strings;

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  late bool _expanded = widget.initiallyExpanded;

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
              onTap: () => setState(() => _expanded = !_expanded),
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
                              if (highlight) ...<Widget>[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.accentSoft,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    widget.strings.todayBadge,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.strings.lessonsCount(widget.lessons.length),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
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
            child: _expanded
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

class _AliasInfoCard extends StatelessWidget {
  const _AliasInfoCard({required this.aliases, required this.strings});

  final Map<String, List<String>> aliases;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final socialAliases = aliases['Обществознание'] ??
        const <String>['общество', 'общага', 'квобщество'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 17,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings.aliasCardTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      strings.aliasCardSubtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              for (final alias in socialAliases.take(3))
                SoftChip(label: '#$alias'),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: palette.textMuted,
              ),
              const SoftChip(
                label: 'Обществознание',
                icon: Icons.groups_rounded,
                accent: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            strings.aliasCardFooter,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
