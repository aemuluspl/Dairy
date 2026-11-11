import 'package:flutter/material.dart';

/// Число, которое плавно «докручивается» до нового значения.
///
/// Используется в счётчиках, чтобы после свайпа или отметки задачи цифра
/// не подменялась рывком, а мягко перетекала к новому значению.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 380),
    this.curve = Curves.easeOutCubic,
    this.textAlign,
  });

  final int value;
  final TextStyle style;
  final Duration duration;
  final Curve curve;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: value.toDouble(),
        end: value.toDouble(),
      ),
      duration: duration,
      curve: curve,
      builder: (context, animated, _) {
        return Text(
          '${animated.round()}',
          style: style,
          textAlign: textAlign,
        );
      },
    );
  }
}
