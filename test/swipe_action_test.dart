import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:school_diary/core/theme/app_theme.dart';
import 'package:school_diary/data/models/task.dart';
import 'package:school_diary/data/repositories/backup_repository.dart';
import 'package:school_diary/data/repositories/schedule_repository.dart';
import 'package:school_diary/data/repositories/settings_repository.dart';
import 'package:school_diary/data/repositories/task_repository.dart';
import 'package:school_diary/features/tasks/task_card.dart';
import 'package:school_diary/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppState state;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('swipe_test_');
    Hive.init(tempDir.path);
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
    await state.setThemeMode(ThemeMode.dark);
  });

  Future<void> pumpCard(
    WidgetTester tester, {
    required bool completed,
    required Future<void> Function() onSwiped,
  }) async {
    tester.view.physicalSize = const Size(430, 260);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final task = Task.create(
      subject: 'Алгебра',
      description: '419(2)',
      deadline: DateTime.now().add(const Duration(days: 1)),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 30),
              child: TaskCard(
                task: Task(
                  id: task.id,
                  subject: task.subject,
                  description: task.description,
                  deadline: task.deadline,
                  createdAt: task.createdAt,
                  isCompleted: completed,
                ),
                onTap: () {},
                onToggle: () async {},
                onDismissed: onSwiped,
                onOpenDetails: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('свайп влево отмечает задачу выполненной', (
    WidgetTester tester,
  ) async {
    var swiped = false;
    await pumpCard(tester, completed: false, onSwiped: () async {
      swiped = true;
    });

    await tester.fling(find.byType(TaskCard), const Offset(-260, 0), 1200);
    await tester.pumpAndSettle();

    expect(swiped, isTrue);
  });

  testWidgets('свайп вправо возвращает задачу', (WidgetTester tester) async {
    var swiped = false;
    await pumpCard(tester, completed: true, onSwiped: () async {
      swiped = true;
    });

    await tester.fling(find.byType(TaskCard), const Offset(260, 0), 1200);
    await tester.pumpAndSettle();

    expect(swiped, isTrue);
  });

  testWidgets('короткий свайп не срабатывает и карточка возвращается', (
    WidgetTester tester,
  ) async {
    var swiped = false;
    await pumpCard(tester, completed: false, onSwiped: () async {
      swiped = true;
    });

    await tester.drag(find.byType(TaskCard), const Offset(-40, 0));
    await tester.pumpAndSettle();

    expect(swiped, isFalse);
    final transform = tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(TaskCard),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(transform.transform.getTranslation().x, 0);
  });
}
