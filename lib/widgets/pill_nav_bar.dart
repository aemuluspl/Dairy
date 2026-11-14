import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_palette.dart';

class PillNavBar extends StatelessWidget {
  const PillNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    this.stylusWithLines = false,
    this.showSettingsBadge = false,
  });

  /// Сколько места снизу нужно оставлять экранам с `extendBody: true`,
  /// чтобы последний элемент не прятался под капсулой.
  static const double contentInset = 96;

  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// Иконка вкладки New: стилус с линиями или обычный карандаш.
  final bool stylusWithLines;

  /// Красная точка на вкладке Settings, когда доступно обновление.
  final bool showSettingsBadge;

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
    // Обёртка прозрачная: при extendBody фон под капсулой рисует сам экран.
    return SafeArea(
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
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / items.length;
                  return Stack(
                    children: <Widget>[
                      // Ездящая капсула: один слой, без обрезки и теней.
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        left: currentIndex * itemWidth,
                        top: 0,
                        bottom: 0,
                        width: itemWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: palette.accent,
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          for (var index = 0; index < items.length; index++)
                            Expanded(
                              child: _NavButton(
                                data: items[index],
                                selected: currentIndex == index,
                                badge: showSettingsBadge &&
                                    index == items.length - 1,
                                onTap: () {
                                  if (currentIndex == index) return;
                                  HapticFeedback.selectionClick();
                                  onSelect(index);
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
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
    this.badge = false,
  });

  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: selected ? 1 : 0),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) {
            // Плавный переход цвета вместо резкого перекрашивания.
            final color = Color.lerp(palette.textMuted, palette.onAccent, t)!;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Transform.scale(
                    scale: 1 + 0.08 * t,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Icon(data.icon, size: 22, color: color),
                        if (badge)
                          Positioned(
                            right: -2,
                            top: -1,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: palette.danger,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      selected ? palette.accent : palette.card,
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.label,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 9.5,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
