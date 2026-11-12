import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/i18n/app_strings.dart';

class SettingsRepository {
  static const String boxName = 'settings';
  static const String _themeKey = 'themeMode';
  static const String _languageKey = 'language';
  static const String _showRoomsKey = 'showRooms';
  static const String _newIconLinesKey = 'newIconLines';

  late final Box<dynamic> _box;

  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(boxName);
  }

  ThemeMode loadThemeMode() {
    switch (_box.get(_themeKey)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) => _box.put(_themeKey, mode.name);

  AppLanguage loadLanguage() => AppLanguage.fromId(_box.get(_languageKey));

  Future<void> saveLanguage(AppLanguage language) =>
      _box.put(_languageKey, language.id);

  bool loadShowRooms() => _box.get(_showRoomsKey) as bool? ?? true;

  Future<void> saveShowRooms(bool value) => _box.put(_showRoomsKey, value);

  bool loadNewIconLines() => _box.get(_newIconLinesKey) as bool? ?? false;

  Future<void> saveNewIconLines(bool value) =>
      _box.put(_newIconLinesKey, value);
}
