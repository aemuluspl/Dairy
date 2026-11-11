import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:school_diary/app.dart';
import 'package:school_diary/data/repositories/backup_repository.dart';
import 'package:school_diary/data/repositories/schedule_repository.dart';
import 'package:school_diary/data/repositories/settings_repository.dart';
import 'package:school_diary/data/repositories/task_repository.dart';
import 'package:school_diary/features/tasks/task_card.dart';
import 'package:school_diary/features/tasks/task_detail_screen.dart';
import 'package:school_diary/state/app_state.dart';
import 'package:school_diary/widgets/pill_nav_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppState state;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('school_diary_test_');
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
  });

  testWidgets('полный сценарий: вброс, задачи, календарь, детали', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1290, 2790);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const SchoolDiaryApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Стартовый экран — New.
    expect(find.text('New'), findsWidgets);
    expect(find.text('Распределить'), findsOneWidget);

    // Две задачи в одном вбросе.
    await tester.enterText(
      find.byType(TextField),
      '#алгебра упр 15 #физика параграф 5',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Распределить · 2'), findsOneWidget);
    await tester.tap(find.textContaining('Распределить · 2'));
    await tester.pump();

    // Hive пишет на диск настоящими Future — даём им завершиться вне
    // фейкового времени теста, иначе спиннер крутится бесконечно.
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (state.tasks.length < 2 && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(state.tasks, hasLength(2));

    // Переключаемся на «Задачи» через нижнюю навигацию.
    await tester.tap(
      find.descendant(
        of: find.byType(PillNavBar),
        matching: find.text('Tasks'),
      ),
    );
    await tester.pumpAndSettle();

    final algebraCard = find.ancestor(
      of: find.text('Алгебра'),
      matching: find.byType(TaskCard),
    );
    expect(algebraCard, findsOneWidget);

    // Тап по карточке открывает календарь.
    await tester.tap(algebraCard);
    await tester.pumpAndSettle();
    expect(find.text('Дата сдачи'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    // Долгое нажатие открывает экран деталей.
    await tester.longPress(algebraCard);
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailScreen), findsOneWidget);
    expect(find.text('ДОМАШНЕЕ ЗАДАНИЕ'), findsOneWidget);
    expect(find.text('Изменить дату'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailScreen), findsNothing);

    // Расписание и база открываются без ошибок.
    await tester.tap(
      find.descendant(
        of: find.byType(PillNavBar),
        matching: find.text('Schedule'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Пн – Сб'), findsOneWidget);
    expect(find.text('Понедельник'), findsOneWidget);

    // Суббота ниже по списку — прокручиваем.
    await tester.drag(find.text('Понедельник'), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.text('Суббота'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(PillNavBar),
        matching: find.text('Settings'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Экспорт базы (JSON)'), findsOneWidget);

    // Переключение темы.
    await tester.tap(find.text('Тёмная'));
    await tester.pumpAndSettle();
    expect(state.themeMode, ThemeMode.dark);

    // Даём снекбарам исчезнуть, чтобы не осталось таймеров.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('языковые режимы переключают подписи', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1290, 2790);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const SchoolDiaryApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(PillNavBar),
        matching: find.text('Settings'),
      ),
    );
    await tester.pumpAndSettle();

    // Полный английский режим.
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('Show room numbers'), findsOneWidget);
    expect(find.text('LANGUAGE'), findsOneWidget);

    // Смешанный режим: вкладки английские, содержимое русское.
    await tester.tap(find.text('Mixed'));
    await tester.pumpAndSettle();
    expect(find.text('ОФОРМЛЕНИЕ'), findsOneWidget);
    expect(find.text('Показывать кабинеты'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('редактор расписания добавляет и удаляет урок', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1290, 2790);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const SchoolDiaryApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(PillNavBar),
        matching: find.text('Schedule'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();

    // Подписи зависят от текущего языкового режима.
    String label(String ru, String en) => state.strings.isEnglish ? en : ru;

    expect(find.text(label('Редактировать', 'Edit')), findsOneWidget);
    expect(
      find.text(label(
        'Перетащи уроки, чтобы поменять порядок',
        'Drag lessons to reorder them',
      )),
      findsOneWidget,
    );

    final mondayBefore = state.lessonsFor(DateTime.monday).length;

    await tester.tap(find.text(label('Добавить урок', 'Add lesson')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Тестовый предмет');
    await tester.enterText(find.byType(TextField).at(1), '999');
    await tester.tap(find.text(label('Сохранить', 'Save')));
    await tester.pump();

    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (state.lessonsFor(DateTime.monday).length == mondayBefore &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      // Даём Hive дописать и notifyListeners сработать.
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    });
    await tester.pumpAndSettle();

    expect(state.lessonsFor(DateTime.monday).length, mondayBefore + 1);
    expect(
      state.lessonsFor(DateTime.monday).last.subject,
      'Тестовый предмет',
    );

    // Новый урок в конце списка — прокручиваем к нему.
    final listCenter = tester.getCenter(find.byType(ReorderableListView));
    for (var attempt = 0; attempt < 6; attempt++) {
      if (find.text('Тестовый предмет').evaluate().isNotEmpty) break;
      await tester.dragFrom(listCenter, const Offset(0, -220));
      await tester.pumpAndSettle();
    }

    // Удаляем добавленный урок через диалог.
    await tester.tap(find.text('Тестовый предмет'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label('Удалить', 'Delete')));
    await tester.pump();

    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (state.lessonsFor(DateTime.monday).length != mondayBefore &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    });
    await tester.pumpAndSettle();

    expect(state.lessonsFor(DateTime.monday).length, mondayBefore);

    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();
    expect(find.text(label('Расписание', 'Schedule')), findsOneWidget);
  });
}
