import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/pill_nav_bar.dart';
import '../inbox/inbox_screen.dart';
import '../schedule/schedule_screen.dart';
import '../settings/settings_screen.dart';
import '../tasks/tasks_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _currentIndex = _tabFromUrl();

  static const List<Widget> _pages = <Widget>[
    InboxScreen(),
    TasksScreen(),
    ScheduleScreen(),
    SettingsScreen(),
  ];

  /// Небольшой бонус для веба: `?tab=schedule` открывает нужную вкладку.
  /// Полезно для превью и отладки, на Android просто всегда New.
  static int _tabFromUrl() {
    if (!kIsWeb) return 0;
    switch (Uri.base.queryParameters['tab']) {
      case 'tasks':
        return 1;
      case 'schedule':
        return 2;
      case 'settings':
        return 3;
      default:
        return 0;
    }
  }

  void _select(int index) {
    if (index == _currentIndex) return;
    FocusManager.instance.primaryFocus?.unfocus();

    // IndexedStack переключает вкладки мгновенно: промежуточные экраны
    // не пролистываются, состояние каждой страницы сохраняется.
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final state = context.watch<AppState>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // Высоту нижней панели анимируем вместе с клавиатурой, чтобы при её
      // скрытии «Распределить» и контент не прыгали вниз одним кадром.
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        alignment: Alignment.bottomCenter,
        child: keyboardOpen
            ? const SizedBox(width: double.infinity)
            : PillNavBar(
                currentIndex: _currentIndex,
                onSelect: _select,
                stylusWithLines: state.newIconLines,
              ),
      ),
    );
  }
}
