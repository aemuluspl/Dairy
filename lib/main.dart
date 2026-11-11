import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/diagnostics/app_log.dart';
import 'data/repositories/backup_repository.dart';
import 'data/repositories/schedule_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/task_repository.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ловим ошибки фреймворка и необработанные исключения в журнал,
  // чтобы после вылета можно было понять, что случилось.
  FlutterError.onError = (details) {
    AppLog.instance.error(
      'FlutterError',
      error: details.exception,
      stack: details.stack,
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.instance.error('Uncaught', error: error, stack: stack);
    return true;
  };

  await Hive.initFlutter();
  await AppLog.instance.init();
  AppLog.instance.info('Запуск приложения');

  final taskRepository = TaskRepository();
  final scheduleRepository = ScheduleRepository();
  final settingsRepository = SettingsRepository();
  final backupRepository = BackupRepository();

  await Future.wait(<Future<void>>[
    taskRepository.init(),
    scheduleRepository.init(),
    settingsRepository.init(),
    backupRepository.init(),
  ]);

  final appState = AppState(
    taskRepository: taskRepository,
    scheduleRepository: scheduleRepository,
    settingsRepository: settingsRepository,
    backupRepository: backupRepository,
  );
  await appState.load();
  AppLog.instance.info('Загружено задач: ${appState.tasks.length}');

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const SchoolDiaryApp(),
    ),
  );
}
