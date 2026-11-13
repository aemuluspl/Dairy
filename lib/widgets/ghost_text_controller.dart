import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/subject_resolver.dart';

/// Контроллер с «призрачным» продолжением слова.
///
/// Введённый текст рисуется обычным цветом, а [ghost] — приглушённым.
/// Курсор при этом остаётся сразу после реального текста.
class GhostTextController extends TextEditingController {
  GhostTextController({super.text});

  Color ghostColor = const Color(0x88888888);
  String _ghost = '';

  String get ghost => _ghost;

  set ghost(String value) {
    if (_ghost == value) return;
    _ghost = value;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    final composing = withComposing ? value.composing : TextRange.empty;
    final composingActive = composing.isValid &&
        !composing.isCollapsed &&
        composing.end <= text.length;

    if (_ghost.isEmpty || composingActive) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final spans = <InlineSpan>[];
    if (text.isNotEmpty) {
      spans.add(TextSpan(text: text));
    }
    spans.add(
      TextSpan(
        text: _ghost,
        style: baseStyle.copyWith(
          color: ghostColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    return TextSpan(style: baseStyle, children: spans);
  }
}

/// Превращает слово в хэштег, когда пользователь ставит пробел.
///
/// Срабатывает только если слово — известный предмет или имеет
/// inline-дополнение. Обычный текст остаётся обычным текстом.
class HashtagAutocompleteFormatter extends TextInputFormatter {
  HashtagAutocompleteFormatter({required this.resolver});

  final SubjectResolver resolver;

  static final RegExp _wordPattern = RegExp(r'#?[A-Za-zА-Яа-яЁё0-9_-]+$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Реагируем только на одиночный пробел в самом конце.
    if (newValue.text.length != oldValue.text.length + 1) return newValue;
    if (!newValue.text.endsWith(' ')) return newValue;
    if (!newValue.selection.isCollapsed) return newValue;
    if (newValue.selection.baseOffset != newValue.text.length) return newValue;

    final withoutSpace = newValue.text.substring(0, newValue.text.length - 1);
    final match = _wordPattern.firstMatch(withoutSpace);
    if (match == null) return newValue;

    final word = match.group(0) ?? '';
    final bare = word.startsWith('#') ? word.substring(1) : word;
    if (bare.length < 2) return newValue;

    final known = resolver.resolveOrNull(bare);
    final completion = known == null ? resolver.completionFor(bare) : null;
    final fullWord = known != null ? bare : completion?.word;
    if (fullWord == null) return newValue;

    final replacement = '#${resolver.tagFor(fullWord)} ';
    final updated = '${newValue.text.substring(0, match.start)}$replacement';

    return TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: updated.length),
    );
  }
}
