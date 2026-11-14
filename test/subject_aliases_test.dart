import 'package:flutter_test/flutter_test.dart';
import 'package:school_diary/domain/subject_aliases.dart';
import 'package:school_diary/domain/subject_resolver.dart';

void main() {
  test('префиксы строятся из названия предмета из расписания', () {
    final aliases = SubjectAliases.build(
      subjects: <String>['Алгебра', 'Русский язык'],
    );

    expect(aliases.keys, containsAll(<String>['Алгебра', 'Русский язык']));
    expect(aliases['Алгебра'], contains('алг'));
    // Полное название — сам ключ, отдельным алиасом его не дублируем.
    expect(aliases['Алгебра'], isNot(contains('алгебра')));
    expect(aliases['Русский язык'], contains('рус'));
    // Служебное слово «язык» не должно давать собственный алиас.
    expect(aliases['Русский язык'], isNot(contains('язык')));
  });

  test('резолвер понимает сгенерированные префиксы', () {
    final resolver = SubjectResolver(
      SubjectAliases.build(subjects: <String>['Алгебра', 'Обществознание']),
    );

    expect(resolver.resolve('алг'), 'Алгебра');
    expect(resolver.resolve('общ'), 'Обществознание');
    expect(resolver.completionFor('алг')?.word, 'Алгебра');
  });

  test('ручные алиасы заменяют сгенерированный набор', () {
    final aliases = SubjectAliases.build(
      subjects: <String>['Алгебра'],
      custom: <String, List<String>>{
        'Алгебра': <String>['матем', 'математика'],
      },
    );

    expect(aliases['Алгебра'], <String>['матем', 'математика']);
    expect(aliases['Алгебра'], isNot(contains('алг')));
  });

  test('одинаковые префиксы не достаются двум предметам', () {
    final aliases = SubjectAliases.build(
      subjects: <String>['Физика', 'Физкультура'],
    );

    final physics = aliases['Физика']!;
    final sport = aliases['Физкультура']!;

    expect(physics, contains('физ'));
    expect(sport, isNot(contains('физ')));
    expect(sport, contains('физк'));
  });

  test('ручной алиас может забрать общий префикс', () {
    final aliases = SubjectAliases.build(
      subjects: <String>['Физика', 'Физкультура'],
      custom: <String, List<String>>{
        'Физкультура': <String>['физра'],
      },
    );

    expect(aliases['Физкультура'], <String>['физра']);
    expect(aliases['Физика'], contains('физ'));
  });
}
