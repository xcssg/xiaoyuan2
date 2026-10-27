import 'package:flutter/material.dart';

import '../theme/q_colors.dart';

ThemeData buildQTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final t = dark ? QColors.darkTheme : QColors.light;
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: t.brand,
      brightness: brightness,
    ).copyWith(
      primary: t.brand,
      surface: t.surfaceSolid,
      error: t.danger,
    ),
    scaffoldBackgroundColor: t.bg,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: t.text,
      displayColor: t.text,
      fontFamilyFallback: const [
        'PingFang SC',
        'Noto Sans CJK SC',
        'Source Han Sans SC',
        'Microsoft YaHei',
      ],
    ),
    iconTheme: IconThemeData(color: t.text2),
    dividerColor: t.line,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: t.brand,
      selectionColor: t.brand.withOpacity(.25),
      selectionHandleColor: t.brand,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xE6101A2A),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 12.5),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
  );
}
