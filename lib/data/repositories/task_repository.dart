import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';

class TaskRepository {
  static const String boxName = 'tasks';

  late final Box<dynamic> _box;

  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(boxName);
  }

  List<Task> loadAll() {
    final tasks = <Task>[];
    for (final value in _box.values) {
      if (value is Map) {
        try {
          tasks.add(Task.fromMap(value));
        } catch (_) {
          // Одна повреждённая запись не должна ронять всё приложение.
        }
      }
    }
    return tasks;
  }

  Future<void> save(Task task) => _box.put(task.id, task.toMap());

  Future<void> saveAll(Iterable<Task> tasks) async {
    await _box.putAll(<String, dynamic>{
      for (final task in tasks) task.id: task.toMap(),
    });
  }

  Future<void> delete(String id) => _box.delete(id);
}
