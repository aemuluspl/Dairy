import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_diary/data/models/holiday.dart';
import 'package:school_diary/data/models/lesson.dart';
import 'package:school_diary/data/seed/default_aliases.dart';
import 'package:school_diary/domain/homework_parser.dart';
import 'package:school_diary/domain/school_calendar.dart';
import 'package:school_diary/domain/subject_resolver.dart';
import 'package:school_diary/widgets/ghost_text_controller.dart';

void main() {
  late HomeworkParser parser;
  late SubjectResolver resolver;

  setUp(() {
    resolver = SubjectResolver(defaultSubjectAliases);
    parser = HomeworkParser(resolver: resolver);
  });

  group('мульти-вброс', () {
    test('делит строку на две независимые задачи', () {
      final result = parser.parse(
        '#алгебра упр 15 #русский параграф 3',
        now: DateTime(2025, 11, 12, 10),
      );

      expect(result, hasLength(2));
      expect(result[0].subject, 'Алгебра');
      expect(result[0].description, 'упр 15');
      expect(result[1].subject, 'Русский язык');
      expect(result[1].description, 'параграф 3');
    });

    test('текст до первого хэштега попадает в первую задачу', () {
      final result = parser.parse(
        'срочно #физика параграф 5 #химия таблица',
        now: DateTime(2025, 11, 12, 10),
      );

      expect(result, hasLength(2));
      expect(result[0].description, 'срочно параграф 5');
    });
  });

  group('очистка описания', () {
    test('удаляет хэштег, оставляя только домашку', () {
      final result = parser.parse(
        '#химия выучить таблицу',
        now: DateTime(2025, 11, 12, 10),
      );

      expect(result.single.subject, 'Химия');
      expect(result.single.description, 'выучить таблицу');
    });

    test('без хэштегов создаёт задачу в «Разное»', () {
      final result = parser.parse(
        'прочитать параграф 12',
        now: DateTime(2025, 11, 12, 10),
      );

      expect(result.single.subject, 'Разное');
      expect(result.single.description, 'прочитать параграф 12');
    });
  });

  group('алиасы', () {
    test('#общага, #общество и #квобщество — Обществознание', () {
      for (final tag in <String>['общага', 'общество', 'квобщество']) {
        final result = parser.parse(
          '#$tag подготовить доклад',
          now: DateTime(2025, 11, 12, 10),
        );
        expect(result.single.subject, 'Обществознание');
      }
    });

    test('Т9 находит предмет по началу слова', () {
      expect(resolver.suggest('общ'), contains('Обществознание'));
      expect(resolver.suggest('физ'), contains('Физика'));
      expect(resolver.suggest('физ'), contains('Физкультура'));
    });

    test('inline-дополнение достраивает каноническое название', () {
      final algebra = resolver.completionFor('ал');
      expect(algebra?.word, 'Алгебра');
      expect(algebra?.completion, 'гебра');

      final social = resolver.completionFor('общ');
      expect(social?.word, 'Обществознание');
      expect(social?.completion, 'ествознание');
    });

    test('пробел ставит канонический тег, а не алиас', () {
      final formatter = HashtagAutocompleteFormatter(resolver: resolver);

      final fromAlias = formatter.formatEditUpdate(
        const TextEditingValue(
          text: 'физ',
          selection: TextSelection.collapsed(offset: 3),
        ),
        const TextEditingValue(
          text: 'физ ',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(fromAlias.text, '#физика ');

      final fromPrefix = formatter.formatEditUpdate(
        const TextEditingValue(
          text: 'ал',
          selection: TextSelection.collapsed(offset: 2),
        ),
        const TextEditingValue(
          text: 'ал ',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      expect(fromPrefix.text, '#алгебра ');
    });

    test('tagFor строит валидный тег', () {
      expect(resolver.tagFor('Обществознание'), 'обществознание');
      expect(resolver.tagFor('Русский язык'), 'русский_язык');
    });
  });

  group('дедлайны и выходные', () {
    test('пятница + «на понедельник» => воскресенье, 20:00', () {
      final friday = DateTime(2025, 11, 14, 10);
      final result = parser.parse(
        '#физика на понедельник параграф 5',
        now: friday,
      );

      expect(result.single.deadline, DateTime(2025, 11, 16, 20));
    });

    test('пятница без даты => пятница, 20:00 (урок в субботу)', () {
      final result = parser.parse(
        '#физика параграф 5',
        now: DateTime(2025, 11, 14, 10),
      );

      expect(result.single.deadline, DateTime(2025, 11, 14, 20));
    });

    test('суббота без даты => воскресенье, 20:00', () {
      final result = parser.parse(
        '#физика параграф 5',
        now: DateTime(2025, 11, 15, 10),
      );

      expect(result.single.deadline, DateTime(2025, 11, 16, 20));
    });

    test('будний день без даты => вечер накануне урока', () {
      final result = parser.parse(
        '#алгебра упр 15',
        now: DateTime(2025, 11, 12, 10),
      );

      expect(result.single.deadline, DateTime(2025, 11, 12, 20));
    });

    test('четверг: дедлайн сегодня, а не в день урока', () {
      final result = parser.parse(
        '#алгебра тест',
        now: DateTime(2025, 11, 13, 10),
      );

      expect(result.single.deadline, DateTime(2025, 11, 13, 20));
    });

    test('после 20:00 дедлайн переезжает на следующий учебный день', () {
      final result = parser.parse(
        '#алгебра тест',
        now: DateTime(2025, 11, 13, 21),
      );

      // Урок уже в субботу, значит дедлайн — пятница, 20:00.
      expect(result.single.deadline, DateTime(2025, 11, 14, 20));
    });

    test('«завтра» и «послезавтра»', () {
      final now = DateTime(2025, 11, 12, 10);
      final tomorrow = parser.parse('#алгебра на завтра упр 15', now: now);
      final afterTomorrow = parser.parse(
        '#алгебра послезавтра упр 15',
        now: now,
      );

      expect(tomorrow.single.deadline, DateTime(2025, 11, 12, 20));
      expect(afterTomorrow.single.deadline, DateTime(2025, 11, 13, 20));
    });

    test('дата «12 ноября»', () {
      final result = parser.parse(
        '#литература 12 ноября глава 3',
        now: DateTime(2025, 11, 9, 10),
      );

      expect(result.single.deadline, DateTime(2025, 11, 11, 20));
    });

    test('дата 12.11', () {
      final result = parser.parse(
        '#литература 12.11 глава 3',
        now: DateTime(2025, 11, 9, 10),
      );

      expect(result.single.deadline, DateTime(2025, 11, 11, 20));
    });
  });

  group('дедлайны по расписанию', () {
    Lesson lesson(String subject) =>
        Lesson(subject: subject, start: '08:00', end: '08:40');

    SchoolCalendar calendarWith(
      Map<int, List<Lesson>> schedule, {
      List<HolidayPeriod> holidays = const <HolidayPeriod>[],
      bool saturdayOff = false,
    }) =>
        SchoolCalendar(
          schedule: schedule,
          holidays: holidays,
          saturdayOff: saturdayOff,
          resolver: resolver,
        );

    final thursday = DateTime(2025, 11, 13, 10);

    test('история только в понедельник => дедлайн в воскресенье', () {
      final calendar = calendarWith(<int, List<Lesson>>{
        DateTime.monday: <Lesson>[lesson('История')],
      });

      final result = parser.parse(
        '#история глава 5',
        now: thursday,
        calendar: calendar,
      );

      expect(result.single.usedSchedule, isTrue);
      expect(result.single.due, DateTime(2025, 11, 17));
      expect(result.single.deadline, DateTime(2025, 11, 16, 20));
    });

    test('алгебра в пятницу => дедлайн в четверг, 20:00', () {
      final calendar = calendarWith(<int, List<Lesson>>{
        DateTime.friday: <Lesson>[lesson('Алгебра')],
      });

      final result = parser.parse(
        '#алгебра упр 15',
        now: thursday,
        calendar: calendar,
      );

      expect(result.single.due, DateTime(2025, 11, 14));
      expect(result.single.deadline, DateTime(2025, 11, 13, 20));
    });

    test('«на следующий урок» = ближайший урок предмета', () {
      final calendar = calendarWith(<int, List<Lesson>>{
        DateTime.friday: <Lesson>[lesson('Алгебра')],
      });

      final result = parser.parse(
        '#алгебра на следующий урок упр 15',
        now: thursday,
        calendar: calendar,
      );

      expect(result.single.due, DateTime(2025, 11, 14));
      expect(result.single.deadline, DateTime(2025, 11, 13, 20));
    });

    test('«через урок» пролистывает один урок предмета', () {
      final calendar = calendarWith(<int, List<Lesson>>{
        DateTime.friday: <Lesson>[lesson('Алгебра')],
        DateTime.tuesday: <Lesson>[lesson('Алгебра')],
      });

      final result = parser.parse(
        '#алгебра через урок упр 15',
        now: thursday,
        calendar: calendar,
      );

      expect(result.single.due, DateTime(2025, 11, 18));
      expect(result.single.deadline, DateTime(2025, 11, 17, 20));
    });

    test('каникулы в понедельник переносят урок на следующую неделю', () {
      final calendar = calendarWith(
        <int, List<Lesson>>{
          DateTime.monday: <Lesson>[lesson('История')],
        },
        holidays: <HolidayPeriod>[
          HolidayPeriod(
            start: DateTime(2025, 11, 17),
            end: DateTime(2025, 11, 17),
          ),
        ],
      );

      final result = parser.parse(
        '#история глава 5',
        now: thursday,
        calendar: calendar,
      );

      expect(result.single.due, DateTime(2025, 11, 24));
      expect(result.single.deadline, DateTime(2025, 11, 23, 20));
    });

    test('суббота-выходной пропускает субботние уроки', () {
      final calendar = calendarWith(
        <int, List<Lesson>>{
          DateTime.saturday: <Lesson>[lesson('Физика')],
          DateTime.monday: <Lesson>[lesson('Физика')],
        },
        saturdayOff: true,
      );

      final result = parser.parse(
        '#физика параграф 5',
        now: DateTime(2025, 11, 14, 10),
        calendar: calendar,
      );

      // Суббота выключена, поэтому ближайший урок — понедельник.
      expect(result.single.due, DateTime(2025, 11, 17));
      expect(result.single.deadline, DateTime(2025, 11, 16, 20));
    });

    test('если предмет только в субботу, а суббота выключена — запасной день',
        () {
      final calendar = calendarWith(
        <int, List<Lesson>>{
          DateTime.saturday: <Lesson>[lesson('Физика')],
        },
        saturdayOff: true,
      );

      final result = parser.parse(
        '#физика параграф 5',
        now: DateTime(2025, 11, 14, 10),
        calendar: calendar,
      );

      expect(result.single.usedSchedule, isFalse);
      expect(result.single.due, DateTime(2025, 11, 17));
      expect(result.single.deadline, DateTime(2025, 11, 16, 20));
    });

    test('явный день недели на каникулах сдвигается вперёд', () {
      final calendar = calendarWith(
        <int, List<Lesson>>{
          DateTime.tuesday: <Lesson>[lesson('История')],
        },
        holidays: <HolidayPeriod>[
          HolidayPeriod(
            start: DateTime(2025, 11, 17),
            end: DateTime(2025, 11, 17),
          ),
        ],
      );

      final result = parser.parse(
        '#история на понедельник глава 5',
        now: thursday,
        calendar: calendar,
      );

      expect(result.single.due, DateTime(2025, 11, 18));
      expect(result.single.deadline, DateTime(2025, 11, 17, 20));
    });

    test('цикл ищет урок через каникулы и границу месяца', () {
      final calendar = calendarWith(
        <int, List<Lesson>>{
          DateTime.monday: <Lesson>[lesson('История')],
        },
        holidays: <HolidayPeriod>[
          HolidayPeriod(
            start: DateTime(2025, 11, 17),
            end: DateTime(2025, 12, 5),
          ),
        ],
      );

      final result = parser.parse(
        '#история глава 5',
        now: thursday,
        calendar: calendar,
      );

      // 17 и 24 ноября, 1 декабря — каникулы; ближайший урок 8 декабря.
      expect(result.single.usedSchedule, isTrue);
      expect(result.single.due, DateTime(2025, 12, 8));
      expect(result.single.deadline, DateTime(2025, 12, 7, 20));
    });

    test('каникулы длиннее 28 дней — запасной дедлайн', () {
      final calendar = calendarWith(
        <int, List<Lesson>>{
          DateTime.monday: <Lesson>[lesson('История')],
        },
        holidays: <HolidayPeriod>[
          HolidayPeriod(
            start: DateTime(2025, 11, 14),
            end: DateTime(2025, 12, 20),
          ),
        ],
      );

      final result = parser.parse(
        '#история глава 5',
        now: thursday,
        calendar: calendar,
      );

      expect(result.single.usedSchedule, isFalse);
    });

    test('старый дедлайн в прошлом пропускается, берётся следующий урок', () {
      final late = DateTime(2025, 11, 14, 21);
      final calendar = calendarWith(<int, List<Lesson>>{
        DateTime.saturday: <Lesson>[lesson('Алгебра')],
        DateTime.monday: <Lesson>[lesson('Алгебра')],
      });

      final result = parser.parse(
        '#алгебра упр 15',
        now: late,
        calendar: calendar,
      );

      // Суббота уже наступила, её дедлайн (пятница, 20:00) прошёл —
      // парсер берёт понедельник.
      expect(result.single.due, DateTime(2025, 11, 17));
      expect(result.single.deadline, DateTime(2025, 11, 16, 20));
    });
  });

  group('слипшийся текст', () {
    test('#алгебраупр15 делится на тег и описание', () {
      final result = parser.parse(
        '#алгебраупр15',
        now: DateTime(2025, 11, 13, 10),
      );

      expect(result.single.subject, 'Алгебра');
      expect(result.single.description, 'упр15');
    });

    test('#физикапараграф5 сохраняет хвост в описании', () {
      final result = parser.parse(
        '#физикапараграф5',
        now: DateTime(2025, 11, 13, 10),
      );

      expect(result.single.subject, 'Физика');
      expect(result.single.description, 'параграф5');
    });

    test('известный тег не режется', () {
      final result = parser.parse(
        '#русский_язык упр 3',
        now: DateTime(2025, 11, 13, 10),
      );

      expect(result.single.subject, 'Русский язык');
      expect(result.single.description, 'упр 3');
    });
  });
}
