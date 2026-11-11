import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';

/// Страховка от потери домашки: снимок всех задач после каждого изменения.
///
/// Храним две копии — последнюю и предыдущую. Если база внезапно опустеет
/// или задача потеряется, её можно вернуть из настроек.
class BackupRepository {
  static const String boxName = 'diary_backups';
  static const String _latestKey = 'latest';
  static const String _previousKey = 'previous';

  late final Box<dynamic> _box;

  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(boxName);
  }

  DateTime? get latestAt => _read(_latestKey)?.at;

  int get latestCount => _read(_latestKey)?.count ?? 0;

  bool get hasBackup => latestCount > 0;

  List<Task>? loadLatest() {
    final data = _read(_latestKey);
    if (data == null) return null;
    try {
      final decoded = jsonDecode(data.json);
      if (decoded is! List) return null;
      return <Task>[
        for (final item in decoded)
          if (item is Map) Task.fromMap(item),
      ];
    } catch (_) {
      return null;
    }
  }

  Future<void> save(List<Task> tasks) async {
    final snapshot = jsonEncode(<Map<String, dynamic>>[
      for (final task in tasks) task.toMap(),
    ]);

    final previous = _read(_latestKey);
    final current = _Snapshot(
      at: DateTime.now(),
      count: tasks.length,
      json: snapshot,
    );

    if (previous != null) {
      await _box.put(_previousKey, previous.toMap());
    }
    await _box.put(_latestKey, current.toMap());
  }

  _Snapshot? _read(String key) {
    final raw = _box.get(key);
    if (raw is Map) return _Snapshot.fromMap(raw);
    return null;
  }
}

class _Snapshot {
  const _Snapshot({
    required this.at,
    required this.count,
    required this.json,
  });

  final DateTime at;
  final int count;
  final String json;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'at': at.toIso8601String(),
        'count': count,
        'json': json,
      };

  factory _Snapshot.fromMap(Map<dynamic, dynamic> map) {
    return _Snapshot(
      at: DateTime.tryParse(map['at']?.toString() ?? '') ?? DateTime.now(),
      count: int.tryParse(map['count']?.toString() ?? '') ?? 0,
      json: map['json']?.toString() ?? '[]',
    );
  }
}
