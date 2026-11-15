import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import '../core/theme/app_radii.dart';

/// Поле ввода в стиле приложения.
///
/// Системная рамка и заливка полностью отключены: скруглённый контейнер
/// рисует само поле, поэтому фон и радиус совпадают с остальными карточками.
class AppInputField extends StatelessWidget {
  const AppInputField({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
    this.autofocus = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.style,
    this.focusNode,
  });

  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final int minLines;
  final int maxLines;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextStyle? style;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(AppRadii.field),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (label != null) ...<Widget>[
            Text(
              label!,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: 4),
          ],
          TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            minLines: minLines,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            autocorrect: autocorrect,
            enableSuggestions: enableSuggestions,
            cursorColor: palette.accent,
            style: style ??
                TextStyle(
                  fontSize: 14.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: palette.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
