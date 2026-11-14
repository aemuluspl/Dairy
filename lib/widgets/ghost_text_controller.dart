import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/subject_resolver.dart';

/// Контроллер с «призрачным» продолжением слова.
///
/// Введённый текст рисуется обычным цветом, а [ghost] — приглушённым.
/// Призрачный хвост вставляется строго в позицию курсора, а не в конец
/// всего текста, поэтому подсказка работает и в середине строки.
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

    final selection = value.selection;
    final rawOffset = selection.isValid ? selection.baseOffset : text.length;
    final cursor =
        rawOffset < 0 ? 0 : (rawOffset > text.length ? text.length : rawOffset);
    final before = text.substring(0, cursor);
    final after = text.substring(cursor);

    final spans = <InlineSpan>[
      if (before.isNotEmpty) TextSpan(text: before),
      TextSpan(
        text: _ghost,
        style: baseStyle.copyWith(
          color: ghostColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      if (after.isNotEmpty) TextSpan(text: after),
    ];
    return TextSpan(style: baseStyle, children: spans);
  }
}

/// Превращает слово в хэштег, когда пользователь ставит пробел.
///
/// Слово определяется по позиции курсора, поэтому замена работает и в
/// середине строки. Срабатывает только если слово — известный предмет или
/// имеет inline-дополнение; обычный текст остаётся обычным текстом.
class HashtagAutocompleteFormatter extends TextInputFormatter {
  HashtagAutocompleteFormatter({required this.resolver});

  final SubjectResolver resolver;

  static final RegExp _wordPattern = RegExp(r'#?[A-Za-zА-Яа-яЁё0-9_-]+$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.selection.isCollapsed) return newValue;

    final text = newValue.text;
    final cursor = newValue.selection.baseOffset;
    if (cursor <= 0 || cursor > text.length) return newValue;
    // Пробел только что появился прямо перед курсором.
    if (text[cursor - 1] != ' ') return newValue;

    final before = text.substring(0, cursor - 1);
    final match = _wordPattern.firstMatch(before);
    if (match == null) return newValue;

    final word = match.group(0) ?? '';
    final bare = word.startsWith('#') ? word.substring(1) : word;
    if (bare.length < 2) return newValue;

    final known = resolver.resolveOrNull(bare);
    final completion = known == null ? resolver.completionFor(bare) : null;
    // Для известного слова берём каноническое имя, а не введённый алиас:
    // «физ» + пробел → #физика, «общага» → #обществознание.
    final fullWord = known ?? completion?.word;
    if (fullWord == null) return newValue;

    final replacement = '#${resolver.tagFor(fullWord)} ';
    final updated = '${text.substring(0, match.start)}$replacement'
        '${text.substring(cursor)}';

    return TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(
        offset: match.start + replacement.length,
      ),
    );
  }
}
