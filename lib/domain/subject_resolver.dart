import '../data/seed/default_aliases.dart';

/// Превращает тег из текста в канонический предмет расписания.
/// Здесь же живёт система алиасов и подсказки для Т9.
class SubjectResolver {
  SubjectResolver(Map<String, List<String>> aliases)
      : _aliases = Map<String, List<String>>.unmodifiable(
          <String, List<String>>{
            for (final entry in aliases.entries)
              entry.key: List<String>.unmodifiable(entry.value),
          },
        ) {
    for (final entry in _aliases.entries) {
      _lookup[_normalize(entry.key)] = entry.key;
      for (final alias in entry.value) {
        _lookup[_normalize(alias)] = entry.key;
      }
    }
  }

  final Map<String, List<String>> _aliases;
  final Map<String, String> _lookup = <String, String>{};

  List<String> get subjects => _aliases.keys.toList(growable: false);

  List<String> aliasesFor(String subject) =>
      _aliases[subject] ?? const <String>[];

  /// #общага / #квобщество / #общество -> «Обществознание».
  String resolve(String rawTag) {
    final normalized = _normalize(rawTag);
    final known = _lookup[normalized];
    if (known != null) return known;
    return _prettify(rawTag);
  }

  /// Подсказки для Т9: и по каноническому имени, и по любому алиасу.
  List<String> suggest(String prefix, {int limit = 3}) {
    final normalizedPrefix = _normalize(prefix);
    if (normalizedPrefix.length < 2) return const <String>[];

    final result = <String>[];
    for (final subject in _aliases.keys) {
      final candidates = <String>[subject, ...?_aliases[subject]];
      final matches = candidates.any(
        (candidate) => _normalize(candidate).startsWith(normalizedPrefix),
      );
      if (matches) result.add(subject);
      if (result.length >= limit) break;
    }
    return result;
  }

  /// Тег, который вставляется в текст при нажатии на чипс/подсказку.
  String tagFor(String subject) {
    final tag = subject
        .toLowerCase()
        .replaceAll('ё', 'е')
        .replaceAll(RegExp(r'[^a-zа-я0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return tag.isEmpty ? 'разное' : tag;
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[^a-zа-я0-9]'), '');

  static String _prettify(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[_-]+'), ' ');
    if (cleaned.isEmpty) return 'Разное';
    return cleaned
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) => '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}

SubjectResolver createDefaultSubjectResolver() =>
    SubjectResolver(defaultSubjectAliases);
