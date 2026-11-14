import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_diary/data/models/bell.dart';
import 'package:school_diary/data/models/lesson.dart';
import 'package:school_diary/services/schedule_transfer_service.dart';

void main() {
  final Map<int, List<Lesson>> schedule = <int, List<Lesson>>{
    DateTime.monday: const <Lesson>[
      Lesson(subject: 'Алгебра', start: '08:00', end: '08:40', room: '204'),
      Lesson(subject: 'Русский язык', start: '08:50', end: '09:30'),
    ],
    DateTime.friday: const <Lesson>[
      Lesson(subject: 'Физика', start: '09:45', end: '10:25', room: '310'),
    ],
  };

  test('JSON-экспорт разбирается обратно без потерь', () {
    final raw = ScheduleTransferService.exportJson(
      schedule: schedule,
      aliases: <String, List<String>>{
        'Алгебра': <String>['матем'],
      },
      bellsByDay: <int, List<Bell>>{
        DateTime.monday: const <Bell>[
          Bell(start: '08:00', end: '08:40'),
          Bell(start: '08:50', end: '09:30'),
        ],
        DateTime.friday: const <Bell>[
          Bell(start: '09:45', end: '10:25'),
        ],
      },
    );

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    expect(decoded['format'], 'hash.schedule');
    expect(decoded['version'], 2);
    expect((decoded['schedule'] as Map<String, dynamic>).keys, contains('6'));
    expect(decoded['bells'], isA<Map<String, dynamic>>());

    final parsed = ScheduleTransferService.tryParse(raw);
    expect(parsed, isNotNull);
    expect(parsed!.schedule[DateTime.monday], hasLength(2));
    expect(parsed.schedule[DateTime.monday]!.first.subject, 'Алгебра');
    expect(parsed.schedule[DateTime.monday]!.first.room, '204');
    expect(parsed.schedule[DateTime.friday]!.single.subject, 'Физика');
    expect(parsed.aliases['Алгебра'], <String>['матем']);
    expect(parsed.bells, hasLength(3));
    expect(parsed.bellsByDay[DateTime.monday], hasLength(2));
    expect(parsed.bellsByDay[DateTime.friday], hasLength(1));
  });

  test('сетка звонков по дням сохраняется в v2', () {
    final raw = ScheduleTransferService.exportJson(
      schedule: <int, List<Lesson>>{
        DateTime.monday: const <Lesson>[
          Lesson(subject: 'РОВ', start: '08:00', end: '08:40'),
          Lesson(subject: 'Алгебра', start: '09:00', end: '09:40'),
        ],
      },
      aliases: const <String, List<String>>{},
      bellsByDay: <int, List<Bell>>{
        DateTime.monday: const <Bell>[
          Bell(start: '08:00', end: '08:40'),
          Bell(start: '09:00', end: '09:40'),
        ],
      },
    );

    final parsed = ScheduleTransferService.tryParse(raw);
    expect(parsed, isNotNull);
    expect(parsed!.bellsByDay[DateTime.monday], hasLength(2));
    expect(parsed.bellsByDay[DateTime.monday]!.last.start, '09:00');
    expect(parsed.bellsByDay[DateTime.tuesday], isNull);
  });

  test('старый формат 1.0.x с modules.homework импортируется', () {
    const raw = '{"format":"school-diary.unified-db","version":1,'
        '"modules":{"homework":{"schedule":{"monday":['
        '{"subject":"История","start":"10:40","end":"11:20","room":"12"}]},'
        '"subjectAliases":{"История":["ист"]}}}}';

    final parsed = ScheduleTransferService.tryParse(raw);

    expect(parsed, isNotNull);
    expect(parsed!.schedule[DateTime.monday]!.single.subject, 'История');
    expect(parsed.schedule[DateTime.monday]!.single.room, '12');
    expect(parsed.aliases['История'], <String>['ист']);
  });

  test('звонки применяются к урокам без времени', () {
    const raw = '{"schedule":{"2":[{"subject":"Физика"}]},'
        '"bells":[{"start":"09:00","end":"09:40"}]}';

    final parsed = ScheduleTransferService.tryParse(raw);

    expect(parsed, isNotNull);
    final lesson = parsed!.schedule[DateTime.tuesday]!.single;
    expect(lesson.start, '09:00');
    expect(lesson.end, '09:40');
  });

  test('текстовый экспорт разбирается обратно', () {
    final raw = ScheduleTransferService.exportText(schedule: schedule);
    expect(raw, contains('ПОНЕДЕЛЬНИК'));
    expect(raw, contains('каб. 204'));
    expect(raw, contains('ЗВОНКИ'));

    final parsed = ScheduleTransferService.tryParse(raw);
    expect(parsed, isNotNull);
    expect(parsed!.schedule[DateTime.monday], hasLength(2));
    expect(parsed.schedule[DateTime.monday]!.first.room, '204');
    expect(parsed.schedule[DateTime.friday]!.single.subject, 'Физика');
    expect(parsed.bells, isNotEmpty);
  });

  test('звонки выводятся без дублей и по порядку', () {
    final bells = ScheduleTransferService.deriveBells(<int, List<Lesson>>{
      DateTime.monday: const <Lesson>[
        Lesson(subject: 'А', start: '09:00', end: '09:40'),
        Lesson(subject: 'Б', start: '08:00', end: '08:40'),
      ],
      DateTime.tuesday: const <Lesson>[
        Lesson(subject: 'В', start: '08:00', end: '08:40'),
      ],
    });

    expect(
      bells.map((bell) => '${bell.start}-${bell.end}'),
      <String>['08:00-08:40', '09:00-09:40'],
    );
  });

  test('пустой и мусорный ввод не ломает импорт', () {
    expect(ScheduleTransferService.tryParse('   '), isNull);
    expect(ScheduleTransferService.tryParse('{не json'), isNull);
    expect(ScheduleTransferService.tryParse('просто текст'), isNull);
  });
}
