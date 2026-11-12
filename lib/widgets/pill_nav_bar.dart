import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_palette.dart';

class PillNavBar extends StatelessWidget {
  const PillNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    this.stylusWithLines = false,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// Иконка вкладки New: стилус с линиями или обычный карандаш.
  final bool stylusWithLines;

  List<_NavItemData> get _items => <_NavItemData>[
        _NavItemData(
          icon: stylusWithLines ? Icons.draw_rounded : Icons.edit_rounded,
          label: 'New',
        ),
        const _NavItemData(
          icon: Icons.checklist_rounded,
          label: 'Tasks',
        ),
        const _NavItemData(
          icon: Icons.calendar_month_rounded,
          label: 'Schedule',
        ),
        const _NavItemData(
          icon: Icons.settings_rounded,
          label: 'Settings',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final items = _items;
    // Плотный фон под панелью: на Android из-под скруглённой «таблетки»
    // проступал чёрный прямоугольник (тот же эффект, что был у карточек
    // при свайпе). Теперь низ экрана закрашен цветом фона, и под панелью
    // физически нечему чернеть.
    return ColoredBox(
      color: palette.background,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: palette.border),
                  // Без размытой тени: BoxShadow на Impeller у некоторых
                  // устройств рисуется прямоугольной чёрной подложкой.
                ),
                // Подсветка выбранного пункта — это фон самого пункта.
                // Никаких анимированных позиций и обрезки: именно они
                // оставляли чёрный прямоугольник при переключении вкладок.
                child: Row(
                  children: <Widget>[
                    for (var index = 0; index < items.length; index++)
                      Expanded(
                        child: _NavButton(
                          data: items[index],
                          selected: currentIndex == index,
                          onTap: () {
                            if (currentIndex == index) return;
                            HapticFeedback.selectionClick();
                            onSelect(index);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = selected ? palette.onAccent : palette.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected ? palette.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedScale(
                  scale: selected ? 1.08 : 1,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: Icon(data.icon, size: 22, color: color),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 9.5,
                    height: 1,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    color: color,
                  ),
                  child: Text(data.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
