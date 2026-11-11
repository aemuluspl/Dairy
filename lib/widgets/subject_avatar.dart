import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import '../core/utils/subject_icons.dart';

class SubjectAvatar extends StatelessWidget {
  const SubjectAvatar({
    super.key,
    required this.subject,
    this.size = 46,
  });

  final String subject;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Icon(
        subjectIcon(subject),
        size: size * 0.45,
        color: palette.textPrimary,
      ),
    );
  }
}
