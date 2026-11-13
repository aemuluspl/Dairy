import '../data/seed/default_aliases.dart';

/// Превращает тег из текста в канонический предмет расписания.
/// Здесь же живёт система алиасов, подсказки и разбор слипшихся тегов.
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
  List<String>? _candidatesCache;

  List<String> get subjects => _aliases.keys.toList(growable: false);

  List<String> aliasesFor(String subject) =>
      _aliases[subject] ?? const <String>[];

  /// #общага / #квобщество / #общество -> «Обществознание».
  String resolve(String rawTag) {
    return resolveOrNull(rawTag) ?? _prettify(rawTag);
  }

  /// Канонический предмет, если тег известен словарю. Иначе `null`.
  String? resolveOrNull(String rawTag) => _lookup[_normalize(rawTag)];

  bool knows(String rawTag) => resolveOrNull(rawTag) != null;

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

  /// Inline-дополнение до **канонического** названия предмета.
  ///
  /// «ал» → «Алгебра», хвост «гебра». Алиасы используются только для
  /// распознавания предмета при вставке, но призрачный хвост всегда
  /// достраивает каноническое имя.
  ({String subject, String word, String completion})? completionFor(
    String prefix,
  ) {
    final normalizedPrefix = _normalize(prefix);
    if (normalizedPrefix.length < 2) return null;

    final matches = <({String subject, int length})>[];
    for (final subject in _aliases.keys) {
      final normalized = _normalize(subject);
      if (normalized.length > normalizedPrefix.length &&
          normalized.startsWith(normalizedPrefix)) {
        matches.add((subject: subject, length: normalized.length));
      }
    }
    if (matches.isEmpty) return null;

    matches.sort((a, b) {
      final byLength = a.length.compareTo(b.length);
      if (byLength != 0) return byLength;
      return a.subject.compareTo(b.subject);
    });

    final best = matches.first.subject;
    final cut = _indexAfterNormalized(best, normalizedPrefix.length);
    if (cut == null || cut >= best.length) return null;

    return (
      subject: best,
      word: best,
      completion: best.substring(cut),
    );
  }

  /// Разбор слипшегося тега: `#алгебраупр15` → тег `алгебра` + хвост `упр15`.
  ///
  /// Срабатывает только если тег целиком неизвестен, а его начало — известный
  /// предмет. Минимальная длина алиаса для разрезания — 4 символа, чтобы
  /// короткие `#ист` / `#лит` не резали случайные слова.
  ({String tag, String rest})? splitGlued(String rawTag) {
    final clean = rawTag.trim();
    if (clean.isEmpty || resolveOrNull(clean) != null) return null;

    final normalized = _normalize(clean);
    if (normalized.isEmpty) return null;

    final candidates = <({String word, String normalized})>[];
    for (final candidate in _candidateWords()) {
      final normalizedCandidate = _normalize(candidate);
      if (normalizedCandidate.length < 4) continue;
      if (normalized.length <= normalizedCandidate.length) continue;
      if (!normalized.startsWith(normalizedCandidate)) continue;
      candidates.add((word: candidate, normalized: normalizedCandidate));
    }
    if (candidates.isEmpty) return null;

    candidates
        .sort((a, b) => b.normalized.length.compareTo(a.normalized.length));

    for (final candidate in candidates) {
      final cut = _indexAfterNormalized(clean, candidate.normalized.length);
      if (cut == null || cut >= clean.length) continue;

      final tag = clean.substring(0, cut).replaceAll(RegExp(r'[_\-\s]+$'), '');
      final rest = clean.substring(cut).replaceAll(RegExp(r'^[_\-\s]+'), '');
      if (tag.isEmpty || rest.isEmpty) continue;
      if (resolveOrNull(tag) == null) continue;
      return (tag: tag, rest: rest);
    }
    return null;
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

  List<String> _candidateWords() {
    return _candidatesCache ??= <String>{
      for (final entry in _aliases.entries) ...<String>[
        entry.key,
        ...entry.value,
      ],
    }.toList(growable: false);
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[^a-zа-я0-9]'), '');

  /// Индекс в исходной строке сразу после [count] «нормализованных» символов.
  static int? _indexAfterNormalized(String raw, int count) {
    var seen = 0;
    for (var index = 0; index < raw.length; index++) {
      final char = raw[index].toLowerCase().replaceAll('ё', 'е');
      if (RegExp(r'[a-zа-я0-9]').hasMatch(char)) {
        seen++;
        if (seen == count) return index + 1;
      }
    }
    return null;
  }

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
