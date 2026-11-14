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
  static const int _basePage = 4000;

  late final PageController _pageController;
  late int _currentIndex;

  /// Пока идёт программная анимация по тапу, события контроллера
  /// игнорируются — иначе капсула «металась» бы по промежуточным страницам.
  bool _isAnimatingByTap = false;

  static const List<Widget> _pages = <Widget>[
    InboxScreen(),
    TasksScreen(),
    ScheduleScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = _tabFromUrl();
    _pageController = PageController(initialPage: _basePage + _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

  Future<void> _select(int index) async {
    if (index == _currentIndex || _isAnimatingByTap) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final currentPage = _pageController.hasClients
        ? (_pageController.page ?? (_basePage + _currentIndex).toDouble())
            .round()
        : _basePage + _currentIndex;

    var delta = index - _currentIndex;
    if (delta > _pageCount ~/ 2) delta -= _pageCount;
    if (delta < -(_pageCount ~/ 2)) delta += _pageCount;

    setState(() {
      _isAnimatingByTap = true;
      _currentIndex = index;
    });

    try {
      await _pageController.animateToPage(
        currentPage + delta,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } finally {
      if (mounted) _isAnimatingByTap = false;
    }
  }

  void _handlePageChanged(int page) {
    if (_isAnimatingByTap) return;
    final index = page % _pageCount;
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final state = context.watch<AppState>();

    return Scaffold(
      // Контент уходит под капсулу навигации: под скруглениями нет
      // непрозрачной полосы, список виден насквозь.
      extendBody: true,
      resizeToAvoidBottomInset: true,
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: _handlePageChanged,
        itemBuilder: (context, page) {
          return _KeepAlivePage(child: _pages[page % _pageCount]);
        },
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

/// Сохраняет состояние вкладки при перелистывании PageView.
class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
