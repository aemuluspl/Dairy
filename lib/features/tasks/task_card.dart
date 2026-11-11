import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_text.dart';
import '../../core/utils/hero_tags.dart';
import '../../data/models/task.dart';
import '../../state/app_state.dart';
import '../../widgets/subject_avatar.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDismissed,
    required this.onOpenDetails,
  });

  final Task task;
  final VoidCallback onTap;
  final Future<void> Function() onToggle;
  final Future<void> Function() onDismissed;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final strings = context.read<AppState>().strings;
    final overdue = !task.isCompleted && task.deadline.isBefore(DateTime.now());

    return _SwipeAction(
      completed: task.isCompleted,
      strings: strings,
      onSwiped: onDismissed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 240),
        opacity: task.isCompleted ? 0.62 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: task.isCompleted
                  ? palette.success.withValues(alpha: 0.35)
                  : palette.border,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.isDark ? 0.25 : 0.035,
                ),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              onLongPress: onOpenDetails,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 14, 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Hero(
                      tag: taskHeroTag(task.id),
                      child: SubjectAvatar(subject: task.subject, size: 44),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 240),
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    height: 1.25,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    color: palette.textPrimary,
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    decorationColor: palette.textSecondary,
                                  ),
                                  child: Text(task.subject),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _CheckButton(
                                completed: task.isCompleted,
                                onTap: onToggle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 240),
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.42,
                              fontWeight: FontWeight.w500,
                              color: palette.textSecondary,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: palette.textSecondary,
                            ),
                            child: Text(
                              task.description.isEmpty
                                  ? strings.noDescription
                                  : task.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.event_rounded,
                                size: 13,
                                color: overdue
                                    ? palette.danger
                                    : palette.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  formatDeadline(
                                    task.deadline,
                                    english: strings.isEnglish,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: overdue
                                        ? palette.danger
                                        : palette.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: onOpenDetails,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                    horizontal: 2,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Text(
                                        strings.details,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: palette.textMuted,
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16,
                                        color: palette.textMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.completed, required this.onTap});

  final bool completed;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 2),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Icon(
            completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            key: ValueKey<bool>(completed),
            size: 22,
            color: completed ? palette.success : palette.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Свайп-действие с цельным скруглённым фоном.
///
/// Встроенный [Dismissible] обрезает подложку прямоугольником по линии сдвига,
/// из-за чего у скруглённой карточки проступали чёрные уголки. Здесь подложка —
/// один скруглённый прямоугольник во всю ширину, а карточка едет поверх него.
class _SwipeAction extends StatefulWidget {
  const _SwipeAction({
    required this.completed,
    required this.strings,
    required this.onSwiped,
    required this.child,
  });

  final bool completed;
  final Strings strings;
  final Future<void> Function() onSwiped;
  final Widget child;

  @override
  State<_SwipeAction> createState() => _SwipeActionState();
}

class _SwipeActionState extends State<_SwipeAction>
    with SingleTickerProviderStateMixin {
  static const double _dismissFraction = 0.32;
  static const double _dismissVelocity = 650;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  Animation<double>? _animation;
  double _offset = 0;
  bool _busy = false;

  @override
  void dispose() {
    _animation?.removeListener(_tick);
    _controller.dispose();
    super.dispose();
  }

  double get _width {
    final size = context.size;
    if (size != null && size.width > 0) return size.width;
    return MediaQuery.sizeOf(context).width;
  }

  void _tick() {
    final animation = _animation;
    if (animation == null) return;
    setState(() => _offset = animation.value);
  }

  void _animateTo(double target, {VoidCallback? onDone}) {
    _animation?.removeListener(_tick);
    _animation = Tween<double>(begin: _offset, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    )..addListener(_tick);
    _controller.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() => _offset = target);
      onDone?.call();
    });
  }

  void _handleDragStart(DragStartDetails details) {
    if (_busy) return;
    _controller.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_busy) return;
    setState(() {
      _offset = (_offset + details.delta.dx).clamp(-_width, _width);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_busy) return;
    final velocity = details.velocity.pixelsPerSecond.dx;
    final shouldDismiss = _offset.abs() > _width * _dismissFraction ||
        velocity.abs() > _dismissVelocity;
    if (!shouldDismiss) {
      _animateTo(0);
      return;
    }
    final direction = _offset != 0 ? _offset.sign : velocity.sign;
    _animateTo(direction * _width, onDone: _finishSwipe);
  }

  Future<void> _finishSwipe() async {
    if (!mounted || _busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    await widget.onSwiped();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _offset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      onHorizontalDragCancel: () {
        if (_busy) return;
        _animateTo(0);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: _SwipeBackground(
              completed: widget.completed,
              alignment:
                  _offset >= 0 ? Alignment.centerLeft : Alignment.centerRight,
              strings: widget.strings,
            ),
          ),
          Transform.translate(
            offset: Offset(_offset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.completed,
    required this.alignment,
    required this.strings,
  });

  final bool completed;
  final Alignment alignment;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: palette.successSoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            completed ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
            color: palette.success,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            completed ? strings.cardUndo : strings.cardDone,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: palette.success,
            ),
          ),
        ],
      ),
    );
  }
}
