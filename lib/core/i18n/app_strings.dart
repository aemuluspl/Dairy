/// Режимы языка приложения.
///
/// [mixed] — навигация и вкладки на английском, содержимое экранов на русском.
/// [english] — полностью английский интерфейс.
enum AppLanguage {
  mixed('mixed'),
  english('english');

  const AppLanguage(this.id);

  final String id;

  static AppLanguage fromId(Object? value) {
    return AppLanguage.values.firstWhere(
      (language) => language.id == value,
      orElse: () => AppLanguage.mixed,
    );
  }
}

/// Все пользовательские строки в одном месте.
///
/// Строки, которые относятся к вкладкам, всегда английские: в смешанном
/// режиме они и должны быть английскими, а в полном — тем более.
class Strings {
  const Strings(this.language);

  final AppLanguage language;

  bool get isEnglish => language == AppLanguage.english;

  String _t(String ru, String en) => isEnglish ? en : ru;

  // ---------------------------------------------------------------------------
  // Навигация
  // ---------------------------------------------------------------------------

  String get navNew => 'New';
  String get navTasks => 'Tasks';
  String get navSchedule => 'Schedule';
  String get navSettings => 'Settings';

  // ---------------------------------------------------------------------------
  // New / быстрый ввод
  // ---------------------------------------------------------------------------

  String get newTitle => 'New';
  String get inputHint => _t('Что задали?', 'What’s due?');
  String distributeLabel(int count) => count > 0
      ? _t('Распределить · $count', 'Distribute · $count')
      : _t('Распределить', 'Distribute');
  String get emptyInputMessage => _t(
        'Сначала напиши домашку и добавь #предмет',
        'Type your homework and add a #subject',
      );
  String get parseFailedMessage => _t(
        'Не получилось найти задачи. Проверь текст',
        'Couldn’t find any tasks. Check the text',
      );
  String addedTasks(int count) =>
      _t('Готово: ${tasksCount(count)}', 'Added: ${tasksCount(count)}');
  String get lightTheme => _t('Светлая тема', 'Light theme');
  String get darkTheme => _t('Тёмная тема', 'Dark theme');

  // ---------------------------------------------------------------------------
  // Tasks
  // ---------------------------------------------------------------------------

  String get tasksTitle => _t('Задачи', 'Tasks');
  String get tasksEmptyTitle => _t('Пока пусто', 'Nothing yet');
  String get tasksEmptyMessage => _t(
        'Добавь домашку — она появится здесь.',
        'Add homework and it will show up here.',
      );
  String activeLine(int count) => '$count $activeWord';
  String get activeWord => _t('в работе', 'open');
  String get swipeHint => _t(
        'Свайп вправо или влево — выполнено',
        'Swipe either way to complete',
      );
  String completedCount(int count) =>
      _t('$count уже закрыто', '$count completed');
  String get completedSection => _t('Выполнено', 'Completed');
  String activeTooltip(int count) =>
      _t('Активных задач: $count', 'Active tasks: $count');
  String get allDoneTitle => _t('Всё выполнено', 'All done');
  String allDoneMessage(int count) => _t(
        'Закрыто задач: $count. Новые появятся после вброса.',
        '$count completed. New tasks will appear when you add homework.',
      );
  String completedSnack(String subject) =>
      _t('$subject: выполнено', '$subject: completed');
  String restoredSnack(String subject) =>
      _t('$subject: возвращено', '$subject: reopened');
  String get noDescription => _t('Без описания', 'No description');
  String get details => _t('Подробнее', 'Details');
  String get cardDone => _t('Выполнено', 'Done');
  String get cardUndo => _t('Вернуть', 'Undo');

  // ---------------------------------------------------------------------------
  // Task details
  // ---------------------------------------------------------------------------

  String get taskTitle => _t('Задача', 'Task');
  String get close => _t('Закрыть', 'Close');
  String get delete => _t('Удалить', 'Delete');
  String get cancel => _t('Отмена', 'Cancel');
  String get save => _t('Сохранить', 'Save');
  String get deleteTaskTitle => _t('Удалить задачу?', 'Delete task?');
  String deleteTaskMessage(String subject) => _t(
        'Задача «$subject» исчезнет из базы.',
        '“$subject” will be removed from the database.',
      );
  String deadlineSnack(String date) => _t('Дедлайн: $date', 'Due: $date');
  String get completedBadge => _t('Выполнено', 'Completed');
  String get homeworkLabel => _t('ДОМАШНЕЕ ЗАДАНИЕ', 'HOMEWORK');
  String get createdLabel => _t('СОЗДАНО', 'CREATED');
  String get changeDate => _t('Изменить дату', 'Change date');
  String get reopen => _t('Вернуть в работу', 'Reopen');
  String get markDone => _t('Отметить выполненной', 'Mark as done');
  String get datePickerHelp => _t('Дата сдачи', 'Due date');

  // ---------------------------------------------------------------------------
  // Schedule
  // ---------------------------------------------------------------------------

  String get scheduleTitle => _t('Расписание', 'Schedule');
  String get scheduleEmptyTitle => _t('Расписание пустое', 'Schedule is empty');
  String get scheduleEmptyMessage => _t(
        'Добавь уроки — они появятся здесь.',
        'Add lessons and they will show up here.',
      );
  String get todayBadge => _t('сегодня', 'today');
  String get tomorrowBadge => _t('завтра', 'tomorrow');
  String statusFirstLesson(String time) =>
      _t('Первый урок в $time', 'First lesson at $time');
  String statusInLesson(String subject, String start) =>
      _t('Сейчас: $subject · $start', 'Now: $subject · $start');
  String statusBreak(String time) =>
      _t('Перемена до $time', 'Break until $time');
  String statusTomorrow(int count) =>
      _t('Завтра: ${lessonsCount(count)}', 'Tomorrow: ${lessonsCount(count)}');
  String statusNextDay(String day) => _t('Дальше: $day', 'Next: $day');
  String get editSchedule => _t('Изменить расписание', 'Edit schedule');
  String get editTitle => _t('Редактировать', 'Edit');
  String get editLesson => _t('Изменить урок', 'Edit lesson');
  String get done => _t('Готово', 'Done');
  String get addLesson => _t('Добавить урок', 'Add lesson');
  String get noLessons => _t('Нет уроков', 'No lessons');
  String get lessonSubject => _t('Предмет', 'Subject');
  String get lessonRoom => _t('Кабинет', 'Room');
  String get lessonStart => _t('Начало', 'Start');
  String get lessonEnd => _t('Конец', 'End');
  String get deleteLessonTitle => _t('Удалить урок?', 'Delete lesson?');
  String get reorderHint => _t(
        'Перетащи уроки, чтобы поменять порядок',
        'Drag lessons to reorder them',
      );
  String get aliasCardTitle => _t('Система алиасов', 'Alias system');
  String get aliasCardSubtitle => _t(
        'Парсер понимает синонимы предметов',
        'The parser understands subject synonyms',
      );
  String get aliasCardFooter => _t(
        'Так же работают #физра, #литра, #инфа, #англ и другие теги. '
            'Алиасы лежат в отдельной коллекции Hive.',
        '#fizra, #litra, #infa, #angl and other tags work too. '
            'Aliases live in a separate Hive collection.',
      );
  String get scheduleStorageNote => _t(
        'Расписание хранится в локальной базе Hive и попадает в JSON-экспорт.',
        'The schedule is stored locally in Hive and included in the JSON export.',
      );
  String get classLabel => '9 «Б»';

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  String get settingsTitle => _t('База и настройки', 'Settings');
  String get appearance => _t('ОФОРМЛЕНИЕ', 'APPEARANCE');
  String get themeLight => _t('Светлая', 'Light');
  String get themeDark => _t('Тёмная', 'Dark');
  String get themeSystem => _t('Система', 'System');
  String get languageSection => _t('ЯЗЫК', 'LANGUAGE');
  String get languageMixed => _t('Смешанный', 'Mixed');
  String get languageMixedHint => _t('Вкладки на английском', 'English tabs');
  String get languageEnglish => _t('English', 'English');
  String get languageEnglishHint =>
      _t('Всё на английском', 'Everything in English');
  String get newIconTitle => _t('Иконка вкладки New', 'New tab icon');
  String get newIconHint =>
      _t('Стилус с линиями или карандаш', 'Stylus with lines or pencil');
  String get scheduleSection => _t('РАСПИСАНИЕ', 'SCHEDULE');
  String get showRooms => _t('Показывать кабинеты', 'Show room numbers');
  String get showRoomsHint => _t(
        'Можно скрыть все сразу или очистить кабинет у отдельного урока',
        'Hide them all at once or clear the room for a single lesson',
      );
  String get localDb => _t('ЛОКАЛЬНАЯ БАЗА', 'LOCAL DATA');
  String get backupTitle => _t('Резервная копия', 'Backup');
  String get backupSubtitle => _t(
        'Снимок задач после каждого изменения',
        'Tasks snapshot after every change',
      );
  String get backupNever => _t('Копий пока нет', 'No backups yet');
  String backupSummary(int count, String at) => _t(
        'Задач: $count · $at',
        'Tasks: $count · $at',
      );
  String get restore => _t('Восстановить', 'Restore');
  String get restoreTitle => _t('Восстановить задачи?', 'Restore tasks?');
  String restoreMessage(int count) => _t(
        'Из копии вернётся $count ${tasksWord(count)}. Текущие задачи останутся на месте.',
        '$count ${tasksWord(count)} will be restored. Current tasks stay in place.',
      );
  String restoredBackupSnack(int count) => _t(
        'Восстановлено задач: $count',
        'Restored $count ${tasksWord(count)}',
      );
  String get inProgress => _t('в работе', 'open');
  String get completed => _t('выполнено', 'completed');
  String get lessonsInSchedule =>
      _t('Уроков в расписании', 'Lessons in schedule');
  String get transfer => _t('ПЕРЕНОС ДАННЫХ', 'TRANSFER');
  String get exportTitle => _t('Экспорт базы (JSON)', 'Export database (JSON)');
  String get exportSubtitle => _t(
        'Задачи, расписание и алиасы в одном файле.',
        'Tasks, schedule and aliases in a single file.',
      );
  String get showJson => _t('Показать JSON', 'Show JSON');
  String get copy => _t('Копировать', 'Copy');
  String get copied => _t(
        'JSON скопирован в буфер обмена',
        'JSON copied to the clipboard',
      );
  String get exportSheetTitle => _t('Экспорт базы', 'Export');
  String exportSheetSubtitle(int tasks, int subjects) => _t(
        '${tasksCount(tasks)} · ${subjectsCount(subjects)}',
        '${tasksCount(tasks)} · ${subjectsCount(subjects)}',
      );
  String get exportHint => _t(
        'Скопируй JSON и сохрани как файл.',
        'Copy the JSON and save it as a file.',
      );
  String get unifiedDb => _t('ГОТОВНОСТЬ К ЕДИНОЙ БД', 'UNIFIED DB');
  String get diagnostics => _t('ДИАГНОСТИКА', 'DIAGNOSTICS');
  String get logsTitle => _t('Журнал', 'Log');
  String get logsSubtitle => _t(
        'Ошибки и действия приложения. Всё хранится только на устройстве.',
        'Errors and app events. Everything stays on the device.',
      );
  String get logsEmpty => _t('Записей пока нет', 'No entries yet');
  String logsSummary(int count, int errors) => _t(
        'Записей: $count · ошибок: $errors',
        'Entries: $count · errors: $errors',
      );
  String get copyLog => _t('Скопировать журнал', 'Copy log');
  String get clearLog => _t('Очистить журнал', 'Clear log');
  String get logsCopied => _t('Журнал скопирован', 'Log copied');
  String get logsCleared => _t('Журнал очищен', 'Log cleared');
  String get clearLogQuestion =>
      _t('Удалить все записи журнала?', 'Delete all log entries?');
  String get back => _t('Назад', 'Back');
  String get modulesTitle =>
      _t('Модули, которые встанут рядом', 'Modules to come');
  String get moduleHomework => _t('Домашка', 'Homework');
  String get moduleNotes => _t('Заметки', 'Notes');
  String get moduleContacts => _t('Контакты PDB', 'PDB Contacts');
  String get moduleMore => _t('Ещё', 'More');
  String get exportFormat => _t('Формат экспорта', 'Export format');
  String get schemaVersion => _t('Версия схемы', 'Schema version');
  String get storage => _t('Хранилище', 'Storage');
  String get footerTitle => _t('Дневник · MVP 1.0.0', 'Diary · MVP 1.0.0');
  String get footerSubtitle => _t(
        'Первый модуль единой информационной базы',
        'First module of a unified database',
      );

  // ---------------------------------------------------------------------------
  // Склонения и даты
  // ---------------------------------------------------------------------------

  String tasksWord(int count) => isEnglish
      ? (count == 1 ? 'task' : 'tasks')
      : _plural(count, 'задача', 'задачи', 'задач');

  String lessonsWord(int count) => isEnglish
      ? (count == 1 ? 'lesson' : 'lessons')
      : _plural(count, 'урок', 'урока', 'уроков');

  String subjectsWord(int count) => isEnglish
      ? (count == 1 ? 'subject' : 'subjects')
      : _plural(count, 'предмет', 'предмета', 'предметов');

  String tasksCount(int count) => '$count ${tasksWord(count)}';

  String lessonsCount(int count) => '$count ${lessonsWord(count)}';

  String subjectsCount(int count) => '$count ${subjectsWord(count)}';

  static String _plural(
    int count,
    String one,
    String few,
    String many,
  ) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) return one;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return few;
    }
    return many;
  }
}
