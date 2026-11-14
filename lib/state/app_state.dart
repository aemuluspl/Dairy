import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../core/diagnostics/app_log.dart';
import '../core/i18n/app_strings.dart';
import '../data/models/bell.dart';
import '../data/models/holiday.dart';
import '../data/models/lesson.dart';
import '../data/models/task.dart';
import '../data/repositories/backup_repository.dart';
import '../data/repositories/schedule_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/task_repository.dart';
import '../domain/homework_parser.dart';
import '../domain/school_calendar.dart';
import '../domain/subject_aliases.dart';
import '../domain/subject_resolver.dart';
import '../services/home_widget_service.dart';
import '../services/schedule_transfer_service.dart';
import '../services/update_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.taskRepository,
    required this.scheduleRepository,
    required this.settingsRepository,
    required this.backupRepository,
  });

  final TaskRepository taskRepository;
  final ScheduleRepository scheduleRepository;
  final SettingsRepository settingsRepository;
  final BackupRepository backupRepository;

  List<Task> _tasks = <Task>[];
  Map<int, List<Lesson>> _schedule = <int, List<Lesson>>{};
  Map<int, List<Bell>> _dayBells = <int, List<Bell>>{};

  /// Ручные алиасы из настроек. Хранятся отдельно от расписания,
  /// чтобы генерация префиксов не затирала пользовательские правки.
  Map<String, List<String>> _customAliases = <String, List<String>>{};
  Map<String, List<String>> _aliases = <String, List<String>>{};
  ThemeMode _themeMode = ThemeMode.system;
  AppLanguage _language = AppLanguage.mixed;
  bool _showRooms = true;
  bool _newIconLines = false;
  bool _saturdayOff = false;
  List<HolidayPeriod> _holidays = <HolidayPeriod>[];
  bool _updateAvailable = false;
  bool _updateChecking = false;
  String? _latestVersion;
  String? _updateUrl;
  DateTime? _lastUpdateCheck;

  late SubjectResolver _resolver;
  late HomeworkParser _parser;

  List<Task> get tasks => List<Task>.unmodifiable(_tasks);
  DateTime? get backupAt => backupRepository.latestAt;
  int get backupCount => backupRepository.latestCount;
  bool get hasBackup => backupRepository.hasBackup;
  Map<int, List<Lesson>> get schedule => _schedule;

  /// Полный словарь: сгенерированные из расписания + ручные алиасы.
  Map<String, List<String>> get aliases => _aliases;

  /// Только ручные алиасы — то, что сохраняется и экспортируется.
  Map<String, List<String>> get customAliases => _customAliases;
  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  bool get showRooms => _showRooms;
  bool get newIconLines => _newIconLines;
  bool get saturdayOff => _saturdayOff;
  List<HolidayPeriod> get holidays =>
      List<HolidayPeriod>.unmodifiable(_holidays);
  Strings get strings => Strings(_language);
  SubjectResolver get resolver => _resolver;
  HomeworkParser get parser => _parser;
  List<Bell> get bells => ScheduleTransferService.deriveBells(_schedule);

  /// Сетка звонков конкретного дня.
  ///
  /// Приоритет: ручная сетка → звонки из уроков этого дня → стандартная.
  List<Bell> bellsFor(int weekday) {
    final custom = _dayBells[weekday];
    if (custom != null && custom.isNotEmpty) {
      return List<Bell>.unmodifiable(custom);
    }
    final derived = ScheduleTransferService.deriveBells(
      <int, List<Lesson>>{weekday: lessonsFor(weekday)},
    );
    if (derived.isNotEmpty) return derived;
    return defaultBellGrid;
  }

  /// Эффективная сетка по дням 1–6 для экспорта и редактора.
  Map<int, List<Bell>> get bellsByDay => <int, List<Bell>>{
        for (var day = DateTime.monday; day <= DateTime.saturday; day++)
          day: bellsFor(day),
      };

  String get version => AppInfo.version;
  bool get updateAvailable => _updateAvailable;
  bool get updateChecking => _updateChecking;
  String? get latestVersion => _latestVersion;
  String? get updateUrl => _updateUrl;
  DateTime? get lastUpdateCheck => _lastUpdateCheck;

  /// Текущий учебный календарь: расписание + каникулы + режим субботы.
  SchoolCalendar get calendar => SchoolCalendar(
        schedule: _schedule,
        holidays: _holidays,
        saturdayOff: _saturdayOff,
        resolver: _resolver,
      );

  /// Разбор текста с учётом реального расписания.
  List<ParsedHomework> parseText(String text, {DateTime? now}) =>
      _parser.parse(text, now: now, calendar: calendar);

  int get activeCount => _tasks.where((task) => !task.isCompleted).length;
  int get completedCount => _tasks.where((task) => task.isCompleted).length;
  int get subjectCount => _resolver.subjects.length;

  Future<void> load() async {
    _tasks = taskRepository.loadAll();

    // Чистый старт: никаких предзаполненных уроков и предметов.
    // Расписание и алиасы приходят только из данных пользователя.
    _schedule = scheduleRepository.loadSchedule();
    _customAliases = scheduleRepository.loadAliases();
    _dayBells = scheduleRepository.loadBells();

    _themeMode = settingsRepository.loadThemeMode();
    _language = settingsRepository.loadLanguage();
    _showRooms = settingsRepository.loadShowRooms();
    _newIconLines = settingsRepository.loadNewIconLines();
    _saturdayOff = settingsRepository.loadSaturdayOff();
    _holidays = settingsRepository.loadHolidays();
    _latestVersion = settingsRepository.loadLatestVersion();
    _updateUrl = settingsRepository.loadUpdateUrl();
    _lastUpdateCheck = settingsRepository.loadLastUpdateCheck();
    _updateAvailable = _latestVersion != null &&
        UpdateService.isNewer(_latestVersion!, AppInfo.version);
    _rebuildResolver();
    _sortTasks();
    notifyListeners();
    unawaited(_syncWidget());

    if (!backupRepository.hasBackup && _tasks.isNotEmpty) {
      unawaited(_saveBackup());
    }
  }

  /// Пересобирает словарь предметов из расписания и ручных алиасов.
  void _rebuildResolver() {
    final custom = <String, List<String>>{};
    final subjects = <String>{};
    for (final lessons in _schedule.values) {
      for (final lesson in lessons) {
        final subject = lesson.subject.trim();
        if (subject.isNotEmpty) subjects.add(subject);
      }
    }
    for (final entry in _customAliases.entries) {
      if (subjects.contains(entry.key)) {
        custom[entry.key] = List<String>.from(entry.value);
      }
    }
    _customAliases = custom;
    _aliases = SubjectAliases.build(subjects: subjects, custom: custom);
    _resolver = SubjectResolver(_aliases);
    _parser = HomeworkParser(resolver: _resolver);
  }

  Future<int> distribute(String rawText) async {
    final parsed = parseText(rawText);
    if (parsed.isEmpty) return 0;

    final created = parsed
        .map(
          (item) => Task.create(
            subject: item.subject,
            description: item.description,
            deadline: item.deadline,
            metadata: <String, dynamic>{'rawTag': item.rawTag},
          ),
        )
        .toList(growable: false);

    await taskRepository.saveAll(created);
    _tasks.addAll(created);
    _sortTasks();
    notifyListeners();
    AppLog.instance.info('Добавлено задач: ${created.length}');
    unawaited(_saveBackup());
    return created.length;
  }

  Task? taskById(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  Future<Task?> toggleCompleted(Task task) async {
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: task.isCompleted ? null : DateTime.now(),
      clearCompletedAt: task.isCompleted,
    );
    await taskRepository.save(updated);
    _replaceTask(updated);
    AppLog.instance.info(
      updated.isCompleted
          ? 'Задача выполнена: ${task.subject}'
          : 'Задача возвращена: ${task.subject}',
    );
    unawaited(_saveBackup());
    return updated;
  }

  Future<void> updateTask(Task task) async {
    await taskRepository.save(task);
    _replaceTask(task);
    AppLog.instance.info('Задача изменена: ${task.subject}');
    unawaited(_saveBackup());
  }

  Future<void> deleteTask(String id) async {
    await taskRepository.delete(id);
    _tasks.removeWhere((task) => task.id == id);
    notifyListeners();
    AppLog.instance.info('Задача удалена: $id');
    unawaited(_saveBackup());
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await settingsRepository.saveThemeMode(mode);
    unawaited(_syncWidget());
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    await settingsRepository.saveLanguage(language);
    unawaited(_syncWidget());
  }

  Future<void> setShowRooms(bool value) async {
    if (_showRooms == value) return;
    _showRooms = value;
    notifyListeners();
    await settingsRepository.saveShowRooms(value);
    unawaited(_syncWidget());
  }

  Future<void> setNewIconLines(bool value) async {
    if (_newIconLines == value) return;
    _newIconLines = value;
    notifyListeners();
    await settingsRepository.saveNewIconLines(value);
  }

  Future<void> setSaturdayOff(bool value) async {
    if (_saturdayOff == value) return;
    _saturdayOff = value;
    notifyListeners();
    await settingsRepository.saveSaturdayOff(value);
    AppLog.instance.info(
      value ? 'Суббота отмечена выходным' : 'Суббота снова учебный день',
    );
    unawaited(_syncWidget());
  }

  Future<void> addHoliday(DateTime start, DateTime end) async {
    _holidays = <HolidayPeriod>[
      ..._holidays,
      HolidayPeriod(start: start, end: end),
    ]..sort((a, b) => a.start.compareTo(b.start));
    notifyListeners();
    await settingsRepository.saveHolidays(_holidays);
    AppLog.instance.info(
      'Добавлены каникулы: ${start.toIso8601String().split('T').first}'
      ' — ${end.toIso8601String().split('T').first}',
    );
  }

  Future<void> removeHoliday(HolidayPeriod period) async {
    _holidays = _holidays
        .where(
          (item) => !(item.start == period.start && item.end == period.end),
        )
        .toList(growable: false);
    notifyListeners();
    await settingsRepository.saveHolidays(_holidays);
    AppLog.instance.info('Каникулы удалены');
  }

  Future<void> saveScheduleDay(int weekday, List<Lesson> lessons) async {
    _schedule = <int, List<Lesson>>{..._schedule, weekday: lessons};
    _rebuildResolver();
    notifyListeners();
    await scheduleRepository.saveSchedule(_schedule);
    await scheduleRepository.saveAliases(_customAliases);
    AppLog.instance.info(
      'Расписание сохранено: день $weekday, уроков ${lessons.length}',
    );
    unawaited(_syncWidget());
  }

  /// Ручной набор алиасов для предмета. Пустой список — явный «без алиасов».
  Future<void> setSubjectAliases(
    String subject,
    List<String> aliases,
  ) async {
    final cleaned = <String>[];
    for (final alias in aliases) {
      final value = alias.trim();
      if (value.isEmpty) continue;
      if (cleaned.any((item) => item.toLowerCase() == value.toLowerCase())) {
        continue;
      }
      cleaned.add(value);
    }

    _customAliases = <String, List<String>>{
      ..._customAliases,
      subject: cleaned,
    };
    _rebuildResolver();
    notifyListeners();
    await scheduleRepository.saveAliases(_customAliases);
    AppLog.instance.info('Алиасы обновлены: $subject');
  }

  List<Lesson> lessonsFor(int weekday) =>
      _schedule[weekday] ?? const <Lesson>[];

  /// Сохраняет ручную сетку звонков дня. Пустой список возвращает
  /// автоматическую сетку из уроков (или стандартную).
  Future<void> setDayBells(int weekday, List<Bell> bells) async {
    final cleaned = bells
        .where((bell) => bell.start.isNotEmpty && bell.end.isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => a.start.compareTo(b.start));
    _dayBells = <int, List<Bell>>{..._dayBells, weekday: cleaned};
    notifyListeners();
    await scheduleRepository.saveBells(_dayBells);
    AppLog.instance.info('Звонки обновлены: день $weekday, ${cleaned.length}');
  }

  /// Проверка обновлений на GitHub Releases.
  ///
  /// Без [force] повторный запрос не чаще одного раза в сутки: результат
  /// последней проверки уже лежит в `settings`.
  Future<bool> checkForUpdates({bool force = false}) async {
    if (_updateChecking) return _updateAvailable;

    final last = _lastUpdateCheck;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < const Duration(hours: 24)) {
      return _updateAvailable;
    }

    _updateChecking = true;
    notifyListeners();
    try {
      final release = await UpdateService.fetchLatest();
      if (release == null) {
        AppLog.instance.info('Проверка обновлений не удалась');
        return _updateAvailable;
      }
      final checkedAt = DateTime.now();
      final available = UpdateService.isNewer(release.version, AppInfo.version);
      _latestVersion = release.version;
      _updateUrl = release.url;
      _lastUpdateCheck = checkedAt;
      _updateAvailable = available;
      await settingsRepository.saveUpdateCache(
        latestVersion: release.version,
        url: release.url,
        checkedAt: checkedAt,
      );
      AppLog.instance.info(
        available
            ? 'Доступно обновление: ${release.tag}'
            : 'Обновлений нет: ${release.tag}',
      );
      return available;
    } finally {
      _updateChecking = false;
      notifyListeners();
    }
  }

  String exportScheduleJson() {
    return ScheduleTransferService.exportJson(
      schedule: _schedule,
      aliases: _customAliases,
      bellsByDay: bellsByDay,
    );
  }

  String exportScheduleText() {
    return ScheduleTransferService.exportText(
      schedule: _schedule,
      bells: bells,
    );
  }

  /// Импорт расписания из JSON или текста. Возвращает число уроков.
  Future<int> importSchedule(String raw) async {
    final parsed = ScheduleTransferService.tryParse(raw);
    if (parsed == null) return -1;

    _schedule = parsed.schedule;
    _customAliases = parsed.aliases;
    _dayBells = parsed.bellsByDay;
    _rebuildResolver();
    notifyListeners();
    await scheduleRepository.saveSchedule(_schedule);
    await scheduleRepository.saveAliases(_customAliases);
    await scheduleRepository.saveBells(_dayBells);
    AppLog.instance.info(
      'Импортировано расписание: уроков '
      '${_schedule.values.fold<int>(0, (sum, day) => sum + day.length)}',
    );
    unawaited(_syncWidget());

    return _schedule.values.fold<int>(0, (sum, day) => sum + day.length);
  }

  /// Возвращает задачи из последней резервной копии.
  Future<int> restoreBackup() async {
    final backup = backupRepository.loadLatest();
    if (backup == null || backup.isEmpty) return 0;

    final byId = <String, Task>{for (final task in _tasks) task.id: task};
    for (final task in backup) {
      byId[task.id] = task;
    }
    await taskRepository.saveAll(byId.values);

    _tasks = byId.values.toList();
    _sortTasks();
    notifyListeners();
    AppLog.instance.info('Восстановлено из копии: ${backup.length}');
    return backup.length;
  }

  Future<void> _saveBackup() async {
    try {
      await backupRepository.save(_tasks);
    } catch (error, stack) {
      AppLog.instance.error(
        'Не удалось сохранить резервную копию',
        error: error,
        stack: stack,
      );
    }
  }

  Future<void> _syncWidget() async {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final dark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system && brightness == Brightness.dark);
    await HomeWidgetService.sync(
      schedule: _schedule,
      showRooms: _showRooms,
      saturdayOff: _saturdayOff,
      dark: dark,
      english: _language == AppLanguage.english,
    );
  }

  Future<void> _replaceTask(Task task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      _tasks.add(task);
    } else {
      _tasks[index] = task;
    }
    _sortTasks();
    notifyListeners();
  }

  void _sortTasks() {
    _tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      if (a.isCompleted) {
        final aDate = a.completedAt ?? a.createdAt;
        final bDate = b.completedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      }
      return a.deadline.compareTo(b.deadline);
    });
  }
}
