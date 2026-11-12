import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/i18n/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/home_shell.dart';
import 'state/app_state.dart';

class SchoolDiaryApp extends StatelessWidget {
  const SchoolDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return MaterialApp(
      title: 'Hash',
      debugShowCheckedModeBanner: false,
      locale: state.language == AppLanguage.english
          ? const Locale('en', 'US')
          : const Locale('ru', 'RU'),
      supportedLocales: const <Locale>[
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: state.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 320),
      themeAnimationCurve: Curves.easeOutCubic,
      home: const HomeShell(),
    );
  }
}
