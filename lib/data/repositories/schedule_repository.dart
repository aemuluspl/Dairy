import 'package:hive_flutter/hive_flutter.dart';

import '../models/bell.dart';
import '../models/lesson.dart';

class ScheduleRepository {
  static const String scheduleBoxName = 'schedule';
  static const String aliasesBoxName = 'aliases';
  static const String bellsBoxName = 'bells';

  late final Box<dynamic> _scheduleBox;
  late final Box<dynamic> _aliasesBox;
  late final Box<dynamic> _bellsBox;

  Future<void> init() async {
    _scheduleBox = await Hive.openBox<dynamic>(scheduleBoxName);
    _aliasesBox = await Hive.openBox<dynamic>(aliasesBoxName);
    _bellsBox = await Hive.openBox<dynamic>(bellsBoxName);
  }

  Map<int, List<Lesson>> loadSchedule() {
    final result = <int, List<Lesson>>{};

    for (final key in _scheduleBox.keys) {
      final weekday = key is int ? key : int.tryParse(key.toString());
      if (weekday == null) continue;
      final raw = _scheduleBox.get(key);
      if (raw is! List) continue;

      result[weekday] =
          raw.whereType<Map>().map(Lesson.fromMap).toList(growable: false);
    }

    for (var day = DateTime.monday; day <= DateTime.sunday; day++) {
      result.putIfAbsent(day, () => <Lesson>[]);
    }
    return result;
  }

  Future<void> saveSchedule(Map<int, List<Lesson>> schedule) async {
    await _scheduleBox.clear();
    for (final entry in schedule.entries) {
      await _scheduleBox.put(
        entry.key,
        entry.value.map((lesson) => lesson.toMap()).toList(growable: false),
      );
    }
  }

  Map<String, List<String>> loadAliases() {
    final result = <String, List<String>>{};
    for (final key in _aliasesBox.keys) {
      final raw = _aliasesBox.get(key);
      if (raw is List) {
        result[key.toString()] =
            raw.map((alias) => alias.toString()).toList(growable: false);
      }
    }
    return result;
  }

  Future<void> saveAliases(Map<String, List<String>> aliases) async {
    await _aliasesBox.clear();
    for (final entry in aliases.entries) {
      await _aliasesBox.put(entry.key, entry.value);
    }
  }

  Map<int, List<Bell>> loadBells() {
    final result = <int, List<Bell>>{};
    for (var day = DateTime.monday; day <= DateTime.sunday; day++) {
      final raw = _bellsBox.get(day);
      if (raw is! List) continue;
      final bells = raw
          .whereType<Map>()
          .map(Bell.fromMap)
          .where((bell) => bell.start.isNotEmpty && bell.end.isNotEmpty)
          .toList(growable: false);
      if (bells.isNotEmpty) {
        result[day] = bells..sort((a, b) => a.start.compareTo(b.start));
      }
    }
    return result;
  }

  Future<void> saveBells(Map<int, List<Bell>> bells) async {
    await _bellsBox.clear();
    for (final entry in bells.entries) {
      if (entry.value.isEmpty) continue;
      await _bellsBox.put(
        entry.key,
        entry.value.map((bell) => bell.toMap()).toList(growable: false),
      );
    }
  }
}
