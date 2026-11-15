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

  /// Номер последнего перехода: быстрые тапы перебивают предыдущий.
  int _flight = 0;

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
    // Тап по уже активной вкладке ничего не делает.
    if (index == _currentIndex) return;
    FocusManager.instance.primaryFocus?.unfocus();

    // Индекс обновляется ДО анимации: капсула и иконка отзываются сразу,
    // а страница догоняет их плавным перелистыванием.
    setState(() {
      _currentIndex = index;
      _isAnimatingByTap = true;
    });

    final flight = ++_flight;
    try {
      await _pageController.animateToPage(
        _targetPage(index),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {
      // Контроллер мог быть уничтожен вместе с экраном.
    }

    // Быстрый повторный тап мог перебить этот переход — тогда флаг
    // останется включённым до завершения последнего.
    if (!mounted || flight != _flight) return;
    _isAnimatingByTap = false;
  }

  /// Ближайшая страница с нужным индексом вкладки.
  ///
  /// Если пользователь тапает повторно посреди анимации, просто
  /// `текущая + дельта` увела бы не туда: считаем от ближайшей страницы.
  int _targetPage(int index) {
    if (!_pageController.hasClients) return _basePage + index;

    final current = (_pageController.page ??
            (_basePage + _currentIndex).toDouble())
        .round();
    final currentIndex = current % _pageCount;
    var delta = index - currentIndex;
    if (delta > _pageCount ~/ 2) delta -= _pageCount;
    if (delta < -(_pageCount ~/ 2)) delta += _pageCount;
    return current + delta;
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
                style: state.navBarStyle,
                showSettingsBadge: state.updateAvailable,
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
