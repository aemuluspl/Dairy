import 'package:flutter/material.dart';

/// Семантическая палитра приложения.
///
/// Все экраны берут цвета отсюда, поэтому светлая и тёмная темы
/// переключаются одним изменением ThemeMode без правок в виджетах.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.card,
    required this.cardElevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
    required this.chip,
  });

  final Color background;
  final Color card;
  final Color cardElevated;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color success;
  final Color successSoft;
  final Color danger;
  final Color dangerSoft;
  final Color chip;

  static const light = AppPalette(
    background: Color(0xFFF4F4F5),
    card: Color(0xFFFFFFFF),
    cardElevated: Color(0xFFFAFAFC),
    border: Color(0xFFEDEDF0),
    textPrimary: Color(0xFF18181B),
    textSecondary: Color(0xFF71717A),
    textMuted: Color(0xFFA1A1AA),
    accent: Color(0xFF18181B),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFF1F1F3),
    success: Color(0xFF16A34A),
    successSoft: Color(0xFFDCFCE7),
    danger: Color(0xFFDC2626),
    dangerSoft: Color(0xFFFEE2E2),
    chip: Color(0xFFF4F4F5),
  );

  static const dark = AppPalette(
    background: Color(0xFF09090B),
    card: Color(0xFF18181B),
    cardElevated: Color(0xFF1E1E22),
    border: Color(0xFF27272A),
    textPrimary: Color(0xFFFAFAFA),
    textSecondary: Color(0xFFA1A1AA),
    textMuted: Color(0xFF71717A),
    accent: Color(0xFFFAFAFA),
    onAccent: Color(0xFF09090B),
    accentSoft: Color(0xFF27272A),
    success: Color(0xFF4ADE80),
    successSoft: Color(0xFF12351F),
    danger: Color(0xFFF87171),
    dangerSoft: Color(0xFF3F1A1A),
    chip: Color(0xFF27272A),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? card,
    Color? cardElevated,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? success,
    Color? successSoft,
    Color? danger,
    Color? dangerSoft,
    Color? chip,
  }) {
    return AppPalette(
      background: background ?? this.background,
      card: card ?? this.card,
      cardElevated: cardElevated ?? this.cardElevated,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      chip: chip ?? this.chip,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardElevated: Color.lerp(cardElevated, other.cardElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
