import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../data/models/lesson.dart';

/// Синхронизация расписания с нативным Android-виджетом.
///
/// Данные кладутся в SharedPreferences плагина `home_widget` под ключом
/// `schedule_data`, после чего провайдер перерисовывает все экземпляры.
class HomeWidgetService {
  const HomeWidgetService._();

  static const String dataKey = 'schedule_data';
  static const String providerName = 'ScheduleWidgetProvider';

  static Future<void> sync({
    required Map<int, List<Lesson>> schedule,
    required bool showRooms,
    required bool saturdayOff,
    required bool dark,
    required bool english,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final days = <String, dynamic>{};
      for (var day = DateTime.monday; day <= DateTime.sunday; day++) {
        days['$day'] = (schedule[day] ?? const <Lesson>[])
            .map((lesson) => lesson.toMap())
            .toList(growable: false);
      }

      final payload = jsonEncode(<String, dynamic>{
        'version': 1,
        'showRooms': showRooms,
        'saturdayOff': saturdayOff,
        'dark': dark,
        'english': english,
        'days': days,
      });

      await HomeWidget.saveWidgetData<String>(dataKey, payload);
      await HomeWidget.updateWidget(androidName: providerName);
    } on MissingPluginException {
      // Плагин не зарегистрирован (тесты, веб, iOS) — виджета просто нет.
    } catch (error, stack) {
      // Виджет — необязательная часть: сбой синхронизации не должен
      // ломать приложение.
      debugPrint('HomeWidget sync failed: $error\n$stack');
    }
  }
}
