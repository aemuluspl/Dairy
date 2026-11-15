/// Внешний вид нижней навигации.
enum NavBarStyle {
  /// Плотная матовая капсула с акцентной заливкой выбранной вкладки.
  classic,

  /// Полупрозрачное матовое стекло: фон за навбаром размывается.
  liquidGlass;

  static NavBarStyle fromId(Object? value) {
    return switch (value) {
      'liquidGlass' => NavBarStyle.liquidGlass,
      _ => NavBarStyle.classic,
    };
  }
}
