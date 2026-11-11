import '../models/lesson.dart';

/// Реальное расписание 9 «Б»: понедельник – суббота.
///
/// Время звонков — стандартная сетка; его можно изменить в редакторе
/// расписания, как и порядок уроков. Кабинеты не заполнены, потому что
/// в исходной таблице их не было.
const Map<int, List<Lesson>> defaultSchedule = <int, List<Lesson>>{
  DateTime.monday: <Lesson>[
    Lesson(subject: 'География', start: '08:00', end: '08:40'),
    Lesson(subject: 'История', start: '08:50', end: '09:30'),
    Lesson(subject: 'Русский язык', start: '09:45', end: '10:25'),
    Lesson(subject: 'Алгебра', start: '10:40', end: '11:20'),
    Lesson(subject: 'Геометрия', start: '11:35', end: '12:15'),
    Lesson(subject: 'Физкультура', start: '12:30', end: '13:10'),
    Lesson(subject: 'Физика', start: '13:25', end: '14:05'),
  ],
  DateTime.tuesday: <Lesson>[
    Lesson(subject: 'Химия', start: '08:00', end: '08:40'),
    Lesson(subject: 'История', start: '08:50', end: '09:30'),
    Lesson(subject: 'Русский язык', start: '09:45', end: '10:25'),
    Lesson(subject: 'Родной язык', start: '10:40', end: '11:20'),
    Lesson(subject: 'Общество', start: '11:35', end: '12:15'),
    Lesson(subject: 'КВ Общ.', start: '12:30', end: '13:10'),
    Lesson(subject: 'Литература', start: '13:25', end: '14:05'),
  ],
  DateTime.wednesday: <Lesson>[
    Lesson(subject: 'Химия', start: '08:00', end: '08:40'),
    Lesson(subject: 'Алгебра', start: '08:50', end: '09:30'),
    Lesson(subject: 'Физкультура', start: '09:45', end: '10:25'),
    Lesson(subject: 'ОБЗР', start: '10:40', end: '11:20'),
    Lesson(subject: 'Родной язык', start: '11:35', end: '12:15'),
    Lesson(subject: 'Английский язык', start: '12:30', end: '13:10'),
  ],
  DateTime.thursday: <Lesson>[
    Lesson(subject: 'Английский язык', start: '08:00', end: '08:40'),
    Lesson(subject: 'Геометрия', start: '08:50', end: '09:30'),
    Lesson(subject: 'Физика', start: '09:45', end: '10:25'),
    Lesson(subject: 'Родная литература', start: '10:40', end: '11:20'),
    Lesson(subject: 'Литература', start: '11:35', end: '12:15'),
  ],
  DateTime.friday: <Lesson>[
    Lesson(subject: 'Русский язык', start: '08:00', end: '08:40'),
    Lesson(subject: 'Литература', start: '08:50', end: '09:30'),
    Lesson(subject: 'Биология', start: '09:45', end: '10:25'),
    Lesson(subject: 'Алгебра', start: '10:40', end: '11:20'),
    Lesson(subject: 'ВиС', start: '11:35', end: '12:15'),
    Lesson(subject: 'География', start: '12:30', end: '13:10'),
    Lesson(subject: 'Информатика', start: '13:25', end: '14:05'),
  ],
  DateTime.saturday: <Lesson>[
    Lesson(subject: 'Физика', start: '08:00', end: '08:40'),
    Lesson(subject: 'Английский язык', start: '08:50', end: '09:30'),
    Lesson(subject: 'Труд', start: '09:45', end: '10:25'),
    Lesson(subject: 'Биология', start: '10:40', end: '11:20'),
  ],
};
