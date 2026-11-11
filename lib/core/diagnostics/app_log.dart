import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Простой журнал действий и ошибок приложения.
///
/// Пишется в Hive, поэтому переживает перезапуск и на Android, и в вебе.
/// Хранится последние [maxEntries] записей — старые вытесняются автоматически.
class AppLog {
  AppLog._();

  static final AppLog instance = AppLog._();

  static const String boxName = 'diary_logs';
  static const int maxEntries = 400;

  Box<String>? _box;
  final List<String> _entries = <String>[];

  /// Записи в порядке добавления (старые сверху).
  List<String> get entries => List<String>.unmodifiable(_entries);

  int get errorCount =>
      _entries.where((line) => line.contains('  ERROR  ')).length;

  bool get isEmpty => _entries.isEmpty;

  Future<void> init() async {
    if (_box != null) return;
    try {
      _box = await Hive.openBox<String>(boxName);
      _entries
        ..clear()
        ..addAll(_box!.values);
    } catch (error) {
      debugPrint('AppLog: не удалось открыть журнал: $error');
      _entries
        ..clear()
        ..add('${_timestamp(DateTime.now())}  WARN  '
            'Не удалось открыть журнал: $error');
    }
  }

  void info(String message) => _append('INFO', message);

  void warn(String message) => _append('WARN', message);

  void error(String message, {Object? error, StackTrace? stack}) {
    final buffer = StringBuffer(message);
    if (error != null) buffer.write(': $error');
    _append('ERROR', buffer.toString(), stack: stack);
  }

  Future<void> clear() async {
    _entries.clear();
    final box = _box;
    if (box == null) return;
    await box.clear();
  }

  String dump() => _entries.join('\n\n');

  void _append(
    String level,
    String message, {
    StackTrace? stack,
  }) {
    final buffer = StringBuffer()
      ..write(_timestamp(DateTime.now()))
      ..write('  ')
      ..write(level)
      ..write('  ')
      ..write(message);
    if (stack != null) {
      final lines = stack
          .toString()
          .trim()
          .split('\n')
          .take(12)
          .map((line) => '    ${line.trim()}')
          .join('\n');
      buffer
        ..write('\n')
        ..write(lines);
    }

    final entry = buffer.toString();
    debugPrint(entry);

    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }

    final box = _box;
    if (box == null) return;
    box.add(entry);
    while (box.length > maxEntries) {
      box.delete(box.keys.first);
    }
  }

  static String _timestamp(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }
}
