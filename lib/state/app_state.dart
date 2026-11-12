import 'dart:async';

import 'package:flutter/material.dart';

import '../core/diagnostics/app_log.dart';
import '../core/i18n/app_strings.dart';
import '../data/models/lesson.dart';
import '../data/models/task.dart';
import '../data/repositories/backup_repository.dart';
import '../data/repositories/schedule_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/task_repository.dart';
import '../data/seed/default_aliases.dart';
import '../data/seed/default_schedule.dart';
import '../domain/homework_parser.dart';
import '../domain/subject_resolver.dart';
import '../services/export_service.dart';

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
  Map<String, List<String>> _aliases = <String, List<String>>{};
  ThemeMode _themeMode = ThemeMode.system;
  AppLanguage _language = AppLanguage.mixed;
  bool _showRooms = true;
  bool _newIconLines = false;

  late SubjectResolver _resolver;
  late HomeworkParser _parser;

  List<Task> get tasks => List<Task>.unmodifiable(_tasks);
  DateTime? get backupAt => backupRepository.latestAt;
  int get backupCount => backupRepository.latestCount;
  bool get hasBackup => backupRepository.hasBackup;
  Map<int, List<Lesson>> get schedule => _schedule;
  Map<String, List<String>> get aliases => _aliases;
  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  bool get showRooms => _showRooms;
  bool get newIconLines => _newIconLines;
  Strings get strings => Strings(_language);
  SubjectResolver get resolver => _resolver;
  HomeworkParser get parser => _parser;

  int get activeCount => _tasks.where((task) => !task.isCompleted).length;
  int get completedCount => _tasks.where((task) => task.isCompleted).length;
  int get subjectCount => _aliases.length;

  Future<void> load() async {
    _tasks = taskRepository.loadAll();

    _aliases = scheduleRepository.loadAliases();
    if (_aliases.isEmpty) {
      _aliases = <String, List<String>>{
        for (final entry in defaultSubjectAliases.entries)
          entry.key: List<String>.from(entry.value),
      };
      await scheduleRepository.saveAliases(_aliases);
    }

    _schedule = scheduleRepository.loadSchedule();
    final seedOutdated =
        scheduleRepository.loadSeedVersion() < ScheduleRepository.seedVersion;
    if (seedOutdated ||
        !_schedule.values.any((lessons) => lessons.isNotEmpty)) {
      _schedule = <int, List<Lesson>>{
        for (final entry in defaultSchedule.entries)
          entry.key: List<Lesson>.from(entry.value),
      };
      await scheduleRepository.saveSchedule(_schedule);
    }

    _themeMode = settingsRepository.loadThemeMode();
    _language = settingsRepository.loadLanguage();
    _showRooms = settingsRepository.loadShowRooms();
    _newIconLines = settingsRepository.loadNewIconLines();
    _resolver = SubjectResolver(_aliases);
    _parser = HomeworkParser(resolver: _resolver);
    _sortTasks();
    notifyListeners();

    if (!backupRepository.hasBackup && _tasks.isNotEmpty) {
      unawaited(_saveBackup());
    }
  }

  Future<int> distribute(String rawText) async {
    final parsed = _parser.parse(rawText);
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
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    await settingsRepository.saveLanguage(language);
  }

  Future<void> setShowRooms(bool value) async {
    if (_showRooms == value) return;
    _showRooms = value;
    notifyListeners();
    await settingsRepository.saveShowRooms(value);
  }

  Future<void> setNewIconLines(bool value) async {
    if (_newIconLines == value) return;
    _newIconLines = value;
    notifyListeners();
    await settingsRepository.saveNewIconLines(value);
  }

  Future<void> saveScheduleDay(int weekday, List<Lesson> lessons) async {
    _schedule = <int, List<Lesson>>{..._schedule, weekday: lessons};
    notifyListeners();
    await scheduleRepository.saveSchedule(_schedule);
    AppLog.instance.info(
      'Расписание сохранено: день $weekday, уроков ${lessons.length}',
    );
  }

  List<Lesson> lessonsFor(int weekday) =>
      _schedule[weekday] ?? const <Lesson>[];

  String exportJson() {
    return ExportService.buildJson(
      tasks: _tasks,
      schedule: _schedule,
      aliases: _aliases,
    );
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
