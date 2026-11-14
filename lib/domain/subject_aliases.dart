/// Собирает словарь алиасов из расписания пользователя.
///
/// Предметы больше не зашиты в код: единственный источник — уроки из Hive.
/// Для каждого названия генерируются короткие префиксные алиасы
/// (`Алгебра` → `алг`, `алге`, `алгеб`…), чтобы парсер понимал `#алг`.
/// Ручные алиасы из настроек полностью заменяют сгенерированный набор.
class SubjectAliases {
  const SubjectAliases._();

  /// Минимальная длина префикса. Три символа — компромисс между
  /// удобством (`#физ`) и ложными срабатываниями.
  static const int minPrefixLength = 3;

  /// Служебные слова, которые встречаются в названиях разных предметов.
  static const Set<String> _stopWords = <String>{
    'язык',
    'языка',
    'языке',
  };

  static Map<String, List<String>> build({
    required Iterable<String> subjects,
    Map<String, List<String>> custom = const <String, List<String>>{},
  }) {
    final names = <String>{
      for (final raw in subjects)
        if (raw.trim().isNotEmpty) raw.trim(),
      for (final raw in custom.keys)
        if (raw.trim().isNotEmpty) raw.trim(),
    }.toList()
      ..sort();

    final canonical = <String, String>{
      for (final subject in names) _normalize(subject): subject,
    };

    // Нормализованный алиас → предмет.
    final taken = <String, String>{...canonical};
    final result = <String, List<String>>{};

    // Сначала раскладываем ручные алиасы: они имеют приоритет.
    for (final subject in names) {
      final aliases = <String>[];
      void add(String candidate, {required bool manual}) {
        final normalized = _normalize(candidate);
        if (normalized.isEmpty || normalized == _normalize(subject)) return;
        if (normalized.length < 2) return;
        final canonicalOwner = canonical[normalized];
        if (canonicalOwner != null && canonicalOwner != subject) return;
        final owner = taken[normalized];
        if (owner != null && owner != subject) {
          if (!manual) return;
        }
        taken[normalized] = subject;
        if (!aliases.any((alias) => _normalize(alias) == normalized)) {
          aliases.add(candidate.trim());
        }
      }

      for (final alias in custom[subject] ?? const <String>[]) {
        add(alias, manual: true);
      }
      result[subject] = aliases;
    }

    // Затем — префиксы для предметов без ручного набора.
    for (final subject in names) {
      if (custom.containsKey(subject)) continue;
      final aliases = result[subject]!;
      for (final candidate in generatedFor(subject)) {
        final normalized = _normalize(candidate);
        if (normalized.isEmpty || normalized == _normalize(subject)) continue;
        final owner = taken[normalized];
        if (owner != null && owner != subject) continue;
        taken[normalized] = subject;
        if (!aliases.any((alias) => _normalize(alias) == normalized)) {
          aliases.add(candidate);
        }
      }
    }

    return result;
  }

  /// Префиксные алиасы одного предмета (без учёта коллизий).
  ///
  /// Алиасы всегда в нижнем регистре: так их удобнее показывать в настройках,
  /// а резолвер всё равно нормализует ввод.
  static List<String> generatedFor(String subject) {
    final aliases = <String>[];
    final words = subject
        .split(RegExp(r'[^A-Za-zА-Яа-яЁё0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);

    for (final rawWord in words) {
      final word = rawWord.toLowerCase();
      if (_stopWords.contains(word)) continue;
      final start =
          minPrefixLength < word.length ? minPrefixLength : word.length;
      for (var length = start; length <= word.length; length++) {
        final prefix = word.substring(0, length);
        if (!aliases.contains(prefix)) aliases.add(prefix);
      }
    }
    return aliases;
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[^a-zа-я0-9]'), '');
}
