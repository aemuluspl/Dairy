import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_text.dart';
import '../../core/utils/max_width_box.dart';
import '../../data/models/task.dart';
import '../../state/app_state.dart';
import '../../widgets/animated_count.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/top_bar.dart';
import 'deadline_picker.dart';
import 'task_card.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final Set<String> _hiddenTaskIds = <String>{};

  Future<void> _pickDate(Task task) async {
    final state = context.read<AppState>();
    final picked = await pickHomeworkDeadline(context, task.deadline);
    if (picked == null || !mounted) return;

    await state.updateTask(task.copyWith(deadline: picked));
    if (!mounted) return;
    showAppSnackBar(
      context,
      '${task.subject}: ${formatDeadline(picked, english: state.strings.isEnglish)}',
      icon: Icons.event_available_rounded,
    );
  }

  Future<void> _toggle(Task task) async {
    final state = context.read<AppState>();
    final updated = await state.toggleCompleted(task);
    if (updated == null || !mounted) return;

    final strings = state.strings;
    showAppSnackBar(
      context,
      updated.isCompleted
          ? strings.completedSnack(task.subject)
          : strings.restoredSnack(task.subject),
      icon:
          updated.isCompleted ? Icons.check_circle_rounded : Icons.undo_rounded,
    );
  }

  Future<void> _toggleBySwipe(Task task) async {
    if (_hiddenTaskIds.contains(task.id)) return;
    setState(() => _hiddenTaskIds.add(task.id));

    final state = context.read<AppState>();
    final updated = await state.toggleCompleted(task);
    if (!mounted) return;

    setState(() => _hiddenTaskIds.remove(task.id));
    if (updated == null) return;

    final strings = state.strings;
    showAppSnackBar(
      context,
      updated.isCompleted
          ? strings.completedSnack(task.subject)
          : strings.restoredSnack(task.subject),
      icon:
          updated.isCompleted ? Icons.check_circle_rounded : Icons.undo_rounded,
    );
  }

  void _openDetails(Task task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailScreen(initialTask: task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    final strings = state.strings;
    final now = DateTime.now();
    final tasks = state.tasks
        .where((task) => !_hiddenTaskIds.contains(task.id))
        .toList(growable: false);
    final active = tasks.where((task) => !task.isCompleted).toList();
    final completed = tasks.where((task) => task.isCompleted).toList();

    final groups = <DateTime, List<Task>>{};
    for (final task in active) {
      final day = dateOnly(task.deadline);
      groups.putIfAbsent(day, () => <Task>[]).add(task);
    }
    final groupDays = groups.keys.toList()..sort();

    final progress = tasks.isEmpty ? 0.0 : completed.length / tasks.length;
    final percent = (progress * 100).round();

    Widget cardFor(Task task) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TaskCard(
          task: task,
          onTap: () => _pickDate(task),
          onToggle: () => _toggle(task),
          onDismissed: () => _toggleBySwipe(task),
          onOpenDetails: () => _openDetails(task),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: MaxWidthBox(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TopBar(
                title: strings.tasksTitle,
                trailing: _CountBadge(
                  count: active.length,
                  tooltip: strings.activeTooltip(active.length),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: tasks.isEmpty
                    ? EmptyState(
                        icon: Icons.task_alt_rounded,
                        title: strings.tasksEmptyTitle,
                        message: strings.tasksEmptyMessage,
                      )
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(top: 2, bottom: 16),
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: palette.card,
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(color: palette.border),
                            ),
                            child: Column(
                              children: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.baseline,
                                            textBaseline:
                                                TextBaseline.alphabetic,
                                            children: <Widget>[
                                              AnimatedCount(
                                                value: active.length,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  height: 1.2,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -0.4,
                                                  color: palette.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                strings.activeWord,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  height: 1.2,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -0.4,
                                                  color: palette.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            completed.isEmpty
                                                ? strings.swipeHint
                                                : strings.completedCount(
                                                    completed.length,
                                                  ),
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              height: 1.35,
                                              fontWeight: FontWeight.w600,
                                              color: palette.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: <Widget>[
                                        AnimatedCount(
                                          value: percent,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                            color: palette.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '%',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                            color: palette.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: SizedBox(
                                    height: 8,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Stack(
                                          children: <Widget>[
                                            Container(color: palette.chip),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 420,
                                              ),
                                              curve: Curves.easeOutCubic,
                                              width: constraints.maxWidth *
                                                  progress,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: palette.accent,
                                                borderRadius:
                                                    BorderRadius.circular(99),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (active.isEmpty)
                            _AllDoneBanner(
                              completedCount: completed.length,
                              strings: strings,
                            )
                          else
                            for (final day in groupDays) ...<Widget>[
                              _GroupHeader(
                                title: groupTitleFor(
                                  day,
                                  now: now,
                                  english: strings.isEnglish,
                                ),
                                count: groups[day]!.length,
                                isOverdue: day.isBefore(dateOnly(now)),
                              ),
                              for (final task in groups[day]!) cardFor(task),
                            ],
                          if (completed.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 6),
                            _GroupHeader(
                              title: strings.completedSection,
                              count: completed.length,
                              isOverdue: false,
                              isCompleted: true,
                            ),
                            for (final task in completed) cardFor(task),
                          ],
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

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.tooltip});

  final int count;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        child: AnimatedCount(
          value: count,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.title,
    required this.count,
    required this.isOverdue,
    this.isCompleted = false,
  });

  final String title;
  final int count;
  final bool isOverdue;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = isOverdue
        ? palette.danger
        : (isCompleted ? palette.success : palette.textSecondary);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
      child: Row(
        children: <Widget>[
          if (isOverdue)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 15,
                color: color,
              ),
            ),
          if (isCompleted)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: color,
              ),
            ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
                color: color,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: palette.chip,
              borderRadius: BorderRadius.circular(99),
            ),
            child: AnimatedCount(
              value: count,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: palette.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllDoneBanner extends StatelessWidget {
  const _AllDoneBanner({required this.completedCount, required this.strings});

  final int completedCount;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.successSoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: palette.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  strings.allDoneTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.allDoneMessage(completedCount),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
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
