import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:school_diary/core/diagnostics/app_log.dart';
import 'package:school_diary/data/repositories/backup_repository.dart';
import 'package:school_diary/data/repositories/schedule_repository.dart';
import 'package:school_diary/data/repositories/settings_repository.dart';
import 'package:school_diary/data/repositories/task_repository.dart';
import 'package:school_diary/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppState state;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('diary_diag_test_');
    Hive.init(tempDir.path);

    await AppLog.instance.init();
    final taskRepository = TaskRepository();
    final scheduleRepository = ScheduleRepository();
    final settingsRepository = SettingsRepository();
    final backupRepository = BackupRepository();
    await Future.wait<void>(<Future<void>>[
      taskRepository.init(),
      scheduleRepository.init(),
      settingsRepository.init(),
      backupRepository.init(),
    ]);

    state = AppState(
      taskRepository: taskRepository,
      scheduleRepository: scheduleRepository,
      settingsRepository: settingsRepository,
      backupRepository: backupRepository,
    );
    await state.load();
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  test('журнал пишет и очищает записи', () async {
    await AppLog.instance.clear();
    AppLog.instance.info('тестовая запись');
    AppLog.instance.error('тестовая ошибка', stack: StackTrace.current);

    final dump = AppLog.instance.dump();
    expect(dump, contains('тестовая запись'));
    expect(dump, contains('ERROR'));
    expect(AppLog.instance.errorCount, 1);

    await AppLog.instance.clear();
    expect(AppLog.instance.entries, isEmpty);
  });

  test('резервная копия сохраняет и возвращает задачи', () async {
    await state.distribute('#алгебра упр 419(2)');

    // Копия сохраняется в фоне.
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!state.hasBackup && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(state.hasBackup, isTrue);
    expect(state.backupCount, 1);

    final id = state.tasks.single.id;
    await state.deleteTask(id);
    expect(state.tasks, isEmpty);

    final restored = await state.restoreBackup();
    expect(restored, 1);
    expect(state.tasks.single.subject, 'Алгебра');
  });
}
