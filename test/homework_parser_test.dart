import 'package:flutter_test/flutter_test.dart';
import 'package:school_diary/data/seed/default_aliases.dart';
import 'package:school_diary/domain/homework_parser.dart';
import 'package:school_diary/domain/subject_resolver.dart';

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

    test('пятница без даты => воскресенье, 20:00', () {
      final result = parser.parse(
        '#физика параграф 5',
        now: DateTime(2025, 11, 14, 10),
      );

      expect(result.single.deadline, DateTime(2025, 11, 16, 20));
    });

    test('суббота без даты => воскресенье, 20:00', () {
      final result = parser.parse(
        '#физика параграф 5',
        now: DateTime(2025, 11, 15, 10),
      );

      expect(result.single.deadline, DateTime(2025, 11, 16, 20));
    });

    test('будний день без даты => следующий день, 20:00', () {
      final result = parser.parse(
        '#алгебра упр 15',
        now: DateTime(2025, 11, 12, 10),
      );

      expect(result.single.deadline, DateTime(2025, 11, 13, 20));
    });

    test('«завтра» и «послезавтра»', () {
      final now = DateTime(2025, 11, 12, 10);
      final tomorrow = parser.parse('#алгебра на завтра упр 15', now: now);
      final afterTomorrow = parser.parse(
        '#алгебра послезавтра упр 15',
        now: now,
      );

      expect(tomorrow.single.deadline, DateTime(2025, 11, 13, 20));
      expect(afterTomorrow.single.deadline, DateTime(2025, 11, 14, 20));
    });

    test('дата «12 ноября»', () {
      final result = parser.parse(
        '#литература 12 ноября глава 3',
        now: DateTime(2025, 11, 9, 10),
      );

      expect(result.single.deadline, DateTime(2025, 11, 12, 20));
    });

    test('дата 12.11', () {
      final result = parser.parse(
        '#литература 12.11 глава 3',
        now: DateTime(2025, 11, 9, 10),
      );

      expect(result.single.deadline, DateTime(2025, 11, 12, 20));
    });
  });
}
