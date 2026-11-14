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
  String deletedSnack(String subject) =>
      _t('Удалено: $subject', 'Deleted: $subject');

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
        'Задача «$subject» будет удалена.',
        '“$subject” will be deleted.',
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
  String get dayOff => _t('Выходной', 'Day off');
  String get tomorrowBadge => _t('завтра', 'tomorrow');
  String statusFirstLesson(String time) =>
      _t('Первый урок в $time', 'First lesson at $time');
  String statusInLesson(String subject, String start, String end) => _t(
        'Сейчас: $subject · $start–$end',
        'Now: $subject · $start–$end',
      );
  String statusNextLesson(String subject, String start, String end) => _t(
        'Далее: $subject ($start–$end)',
        'Next: $subject ($start–$end)',
      );
  String statusBreak(String time) =>
      _t('Перемена до $time', 'Break until $time');
  String statusBreakNext(String time, String subject) => _t(
        'Перемена до $time · Далее: $subject',
        'Break until $time · Next: $subject',
      );
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
  String get dayBellsTitle => _t('Звонки дня', 'Day bells');
  String get dayBellsHint =>
      _t('Своя сетка для каждого дня', 'A custom grid for each day');
  String get dayBellsEdit => _t('Изменить', 'Edit');
  String get dayBellsEmpty => _t('Как по умолчанию', 'Default grid');
  String get addBell => _t('Добавить звонок', 'Add bell');
  String get resetBells => _t('Сбросить', 'Reset');
  String get lessonBellsLabel => _t('Звонки дня', 'Day bells');
  String get deleteLessonTitle => _t('Удалить урок?', 'Delete lesson?');
  String get holidaysTitle => _t('Каникулы и выходные', 'Days off');
  String get holidaysHint => _t(
        'В эти дни уроков нет — парсер их пропускает',
        'No lessons on these days — the parser skips them',
      );
  String get addHolidays => _t('Добавить каникулы', 'Add days off');
  String get noHolidays => _t('Каникул нет', 'No days off yet');
  String get holidaysNow => _t('Каникулы', 'Days off');
  String holidayPeriod(String start, String end) =>
      start == end ? start : '$start — $end';
  String get removeHoliday => _t('Убрать', 'Remove');
  String get saturdayOffTitle => _t('Суббота — выходной', 'Saturday off');
  String get saturdayOffHint => _t(
        'Если в субботу нет уроков, включи этот режим',
        'Turn on if there are no lessons on Saturday',
      );
  String get timeStartTitle => _t('Начало урока', 'Lesson start');
  String get timeEndTitle => _t('Конец урока', 'Lesson end');
  String get timeHours => _t('Часы', 'Hours');
  String get timeMinutes => _t('Минуты', 'Minutes');
  String get classLabel => '9 «Б»';

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  String get settingsTitle => _t('Настройки', 'Settings');

  // Главное меню настроек.
  String get settingsAppearance => _t('Оформление', 'Appearance');
  String get settingsAppearanceSubtitle =>
      _t('Тема и иконка вкладки New', 'Theme and New tab icon');
  String get settingsLanguage => _t('Язык', 'Language');
  String get settingsLanguageSubtitle =>
      _t('Русский, English или смешанный', 'Russian, English or mixed');
  String get settingsSchedule => _t('Расписание', 'Schedule');
  String get settingsScheduleSubtitle =>
      _t('Кабинеты и суббота', 'Rooms and Saturday');
  String get settingsAliases => _t('Алиасы предметов', 'Subject aliases');
  String get settingsAliasesSubtitle =>
      _t('Как сокращать названия в #тегах', 'Short names for #tags');
  String get settingsData => _t('Данные приложения', 'App data');
  String get settingsDataSubtitle =>
      _t('Импорт, экспорт, копия и журнал', 'Import, export, backup and log');
  String get settingsWidget => _t('Настройки виджета', 'Widget settings');
  String get settingsWidgetSubtitle =>
      _t('Вид домашнего экрана', 'Home screen look');
  String get settingsUpdate => _t('Обновление', 'Update');
  String settingsUpdateSubtitle(String version) =>
      _t('Версия $version', 'Version $version');

  // Обновления.
  String get updateCurrentVersion => _t('Текущая версия', 'Current version');
  String get updateChecking => _t('Проверяем…', 'Checking…');
  String get updateCheck => _t('Проверить обновления', 'Check for updates');
  String get updateUpToDate =>
      _t('Установлена последняя версия', 'You’re on the latest version');
  String get updateNotChecked =>
      _t('Проверка ещё не выполнялась', 'Not checked yet');
  String updateAvailableTitle(String version) =>
      _t('Доступна версия $version', 'Version $version is available');
  String get updateDownload => _t('Скачать обновление', 'Download update');
  String get updateCheckFailed =>
      _t('Не удалось проверить обновления', 'Couldn’t check for updates');
  String get updateDownloadFailed =>
      _t('Не удалось открыть ссылку', 'Couldn’t open the link');
  String updateLastCheck(String at) => _t('Проверено: $at', 'Checked: $at');

  // Виджет.
  String get widgetStubTitle => _t('Скоро здесь', 'Coming soon');
  String get widgetStubMessage => _t(
        'Здесь появятся настройки темы и содержимого виджета.',
        'Widget theme and content settings will appear here.',
      );
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
  String get dataSection => _t('ДАННЫЕ', 'DATA');
  String get backupTitle => _t('Резервная копия', 'Backup');
  String get backupNever => _t('Копий пока нет', 'No backups yet');
  String backupUpdatedAt(String at) => _t('Обновлено: $at', 'Updated: $at');
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

  // ---------------------------------------------------------------------------
  // Импорт и экспорт расписания
  // ---------------------------------------------------------------------------

  String get transferSection => _t('РАСПИСАНИЕ', 'SCHEDULE');
  String get transferJson =>
      _t('Скопировать расписание (JSON)', 'Copy schedule (JSON)');
  String get transferJsonHint =>
      _t('Резервная копия всех уроков', 'A backup of all lessons');
  String get transferText =>
      _t('Скопировать расписание (текстом)', 'Copy schedule (as text)');
  String get transferTextHint =>
      _t('Человекочитаемый список уроков', 'A human-readable lesson list');
  String get transferImport =>
      _t('Импортировать расписание', 'Import schedule');
  String get transferImportHintShort =>
      _t('Вставить JSON или текст', 'Paste JSON or text');
  String get transferJsonCopied => _t('JSON скопирован', 'JSON copied');
  String get transferTextCopied => _t('Текст скопирован', 'Text copied');
  String get transferImportTitle => _t('Импорт расписания', 'Import schedule');
  String get transferImportHint => _t(
        'Вставь JSON или текст расписания',
        'Paste JSON or schedule text',
      );
  String get transferPaste => _t('Вставить', 'Paste');
  String transferImported(int lessons) => _t(
        'Импортировано: ${lessonsCount(lessons)}',
        'Imported: ${lessonsCount(lessons)}',
      );
  String get transferImportFailed => _t(
        'Не удалось разобрать расписание',
        'Couldn’t parse the schedule',
      );
  String get transferEmpty => _t(
        'Поле пустое — вставь расписание',
        'The field is empty — paste a schedule',
      );

  // ---------------------------------------------------------------------------
  // Алиасы предметов
  // ---------------------------------------------------------------------------

  String get aliasesSection => _t('АЛИАСЫ ПРЕДМЕТОВ', 'SUBJECT ALIASES');
  String get aliasesEmpty => _t(
        'Добавь уроки — предметы появятся здесь.',
        'Add lessons and subjects will appear here.',
      );
  String aliasesEditTitle(String subject) =>
      _t('Алиасы: $subject', 'Aliases: $subject');
  String get aliasesField => _t('Через запятую', 'Comma separated');
  String aliasesSaved(String subject) =>
      _t('Сохранено: $subject', 'Saved: $subject');
  String get noAliases => _t('Только полное название', 'Full name only');

  // ---------------------------------------------------------------------------
  // Журнал
  // ---------------------------------------------------------------------------

  String get logsTitle => _t('Журнал', 'Log');
  String get logsSubtitle =>
      _t('Ошибки и действия приложения', 'Errors and app events');
  String get logsEmpty => _t('Записей пока нет', 'No entries yet');
  String get copyLog => _t('Скопировать журнал', 'Copy log');
  String get clearLog => _t('Очистить журнал', 'Clear log');
  String get logsCopied => _t('Журнал скопирован', 'Log copied');
  String get logsCleared => _t('Журнал очищен', 'Log cleared');
  String get clearLogQuestion =>
      _t('Удалить все записи журнала?', 'Delete all log entries?');
  String get back => _t('Назад', 'Back');
  String footerTitle(String version) => 'Hash · $version';

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
