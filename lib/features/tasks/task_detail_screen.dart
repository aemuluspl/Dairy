import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/date_text.dart';
import '../../core/utils/hero_tags.dart';
import '../../core/utils/max_width_box.dart';
import '../../data/models/task.dart';
import '../../state/app_state.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/subject_avatar.dart';
import '../../widgets/top_bar.dart';
import 'deadline_picker.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.initialTask});

  final Task initialTask;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.initialTask;
  }

  Future<void> _changeDate() async {
    final picked = await pickHomeworkDeadline(context, _task.deadline);
    if (picked == null || !mounted) return;

    final state = context.read<AppState>();
    final updated = _task.copyWith(deadline: picked);
    await state.updateTask(updated);
    if (!mounted) return;

    setState(() => _task = updated);
    showAppSnackBar(
      context,
      state.strings.deadlineSnack(
        formatDeadline(picked, english: state.strings.isEnglish),
      ),
      icon: Icons.event_available_rounded,
    );
  }

  Future<void> _toggle() async {
    final state = context.read<AppState>();
    final strings = state.strings;
    final updated = await state.toggleCompleted(_task);
    if (updated == null || !mounted) return;

    setState(() => _task = updated);
    showAppSnackBar(
      context,
      updated.isCompleted
          ? strings.completedSnack(updated.subject)
          : strings.restoredSnack(updated.subject),
      icon:
          updated.isCompleted ? Icons.check_circle_rounded : Icons.undo_rounded,
    );
  }

  Future<void> _delete() async {
    final palette = context.palette;
    final strings = context.read<AppState>().strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: palette.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            strings.deleteTaskTitle,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            strings.deleteTaskMessage(_task.subject),
            style: TextStyle(
              color: palette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: palette.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
              ),
              child: Text(strings.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    await context.read<AppState>().deleteTask(_task.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final strings = context.watch<AppState>().strings;
    final overdue =
        !_task.isCompleted && _task.deadline.isBefore(DateTime.now());

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: MaxWidthBox(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TopBar(
                  title: strings.taskTitle,
                  leading: RoundIconButton(
                    icon: Icons.close_rounded,
                    tooltip: strings.close,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  trailing: RoundIconButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: strings.delete,
                    iconColor: palette.danger,
                    onTap: _delete,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    children: <Widget>[
                      const SizedBox(height: 16),
                      Center(
                        child: Hero(
                          tag: taskHeroTag(_task.id),
                          child: SubjectAvatar(
                            subject: _task.subject,
                            size: 86,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _task.subject,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 27,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: overdue
                                ? palette.dangerSoft
                                : palette.accentSoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.event_rounded,
                                size: 15,
                                color: overdue
                                    ? palette.danger
                                    : palette.textPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                formatDeadline(
                                  _task.deadline,
                                  english: strings.isEnglish,
                                ),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: overdue
                                      ? palette.danger
                                      : palette.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_task.isCompleted) ...<Widget>[
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: palette.successSoft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 15,
                                  color: palette.success,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  strings.completedBadge,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: palette.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _InfoCard(
                        label: strings.homeworkLabel,
                        child: SelectableText(
                          _task.description.isEmpty
                              ? strings.noDescription
                              : _task.description,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: _task.description.isEmpty
                                ? palette.textMuted
                                : palette.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _InfoCard(
                        label: strings.createdLabel,
                        child: Text(
                          '${formatHeaderDate(_task.createdAt, english: strings.isEnglish)}, '
                          '${formatTime(_task.createdAt)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _changeDate,
                          icon: const Icon(Icons.event_available_rounded,
                              size: 19),
                          label: Text(strings.changeDate),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _WideAction(
                        icon: _task.isCompleted
                            ? Icons.undo_rounded
                            : Icons.check_circle_outline_rounded,
                        label: _task.isCompleted
                            ? strings.reopen
                            : strings.markDone,
                        onTap: _toggle,
                      ),
                    ],
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _WideAction extends StatelessWidget {
  const _WideAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 19, color: palette.textPrimary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
