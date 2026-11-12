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
  static const int _pageCount = 4;
  static const int _initialPage = 4000;

  late final PageController _pageController;
  late int _currentIndex;

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

  @override
  void initState() {
    super.initState();
    _currentIndex = _tabFromUrl();
    _pageController = PageController(
      initialPage: _initialPage + _currentIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _currentIndex) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final currentPage = _pageController.hasClients
        ? (_pageController.page ?? _initialPage.toDouble()).round()
        : _initialPage + _currentIndex;

    // Идём к соседней вкладке по короткому пути: карусель зациклена,
    // поэтому из New в Settings — один свайп влево, а не пролёт через всё.
    var delta = (index - currentPage % _pageCount) % _pageCount;
    if (delta > _pageCount ~/ 2) delta -= _pageCount;

    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      currentPage + delta,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final state = context.watch<AppState>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (page) {
          final index = page % _pageCount;
          if (index != _currentIndex) setState(() => _currentIndex = index);
        },
        itemBuilder: (context, page) => _pages[page % _pageCount],
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : PillNavBar(
              currentIndex: _currentIndex,
              onSelect: _select,
              stylusWithLines: state.newIconLines,
            ),
    );
  }
}
