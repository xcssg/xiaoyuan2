import 'package:flutter/material.dart';

class QColors {
  const QColors({
    required this.dark,
    required this.brand,
    required this.brand2,
    required this.brandInk,
    required this.bg,
    required this.bgTop,
    required this.surface,
    required this.surfaceSolid,
    required this.surface2,
    required this.surface3,
    required this.field,
    required this.border,
    required this.line,
    required this.glass,
    required this.glassBorder,
    required this.text,
    required this.text2,
    required this.text3,
    required this.danger,
    required this.dangerSoft,
    required this.ok,
    required this.warn,
    required this.dock,
    required this.dockBorder,
    required this.hero,
    required this.avatarGradients,
  });

  final bool dark;
  final Color brand;
  final Color brand2;
  final Color brandInk;
  final Color bg;
  final Color bgTop;
  final Color surface;
  final Color surfaceSolid;
  final Color surface2;
  final Color surface3;
  final Color field;
  final Color border;
  final Color line;
  final Color glass;
  final Color glassBorder;
  final Color text;
  final Color text2;
  final Color text3;
  final Color danger;
  final Color dangerSoft;
  final Color ok;
  final Color warn;
  final Color dock;
  final Color dockBorder;
  final LinearGradient hero;
  final List<LinearGradient> avatarGradients;

  static const List<LinearGradient> _avatars = [
    LinearGradient(colors: [Color(0xFF4F8BFF), Color(0xFF7BC0FF)]),
    LinearGradient(colors: [Color(0xFF7C6CFF), Color(0xFFB39BFF)]),
    LinearGradient(colors: [Color(0xFFFF8FA3), Color(0xFFFFB9A6)]),
    LinearGradient(colors: [Color(0xFF28C2A5), Color(0xFF7EE0C2)]),
    LinearGradient(colors: [Color(0xFFFFB457), Color(0xFFFFD58A)]),
    LinearGradient(colors: [Color(0xFF5A7CF0), Color(0xFF9A8CFF)]),
  ];

  static const QColors light = QColors(
    dark: false,
    brand: Color(0xFF2F6BFF),
    brand2: Color(0xFF6AA8FF),
    brandInk: Color(0xFF1D4ED8),
    bg: Color(0xFFEEF4FF),
    bgTop: Color(0xFFF3F8FF),
    surface: Color(0xDBFFFFFF),
    surfaceSolid: Color(0xFFFFFFFF),
    surface2: Color(0xFFF4F8FF),
    surface3: Color(0xFFEAF2FF),
    field: Color(0x0D102E60),
    border: Color(0x14123060),
    line: Color(0x1A123060),
    glass: Color(0x9EFFFFFF),
    glassBorder: Color(0xCCFFFFFF),
    text: Color(0xFF0D1B2E),
    text2: Color(0xFF5B6B83),
    text3: Color(0xFF93A1B5),
    danger: Color(0xFFEF4444),
    dangerSoft: Color(0x1AEF4444),
    ok: Color(0xFF10B981),
    warn: Color(0xFFF59E0B),
    dock: Color(0x94FFFFFF),
    dockBorder: Color(0xD1FFFFFF),
    hero: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2F6BFF), Color(0xFF5B9BFF), Color(0xFF8FC3FF)],
      stops: [0, .58, 1],
    ),
    avatarGradients: _avatars,
  );

  static const QColors darkTheme = QColors(
    dark: true,
    brand: Color(0xFF5B96FF),
    brand2: Color(0xFF82B5FF),
    brandInk: Color(0xFFCFE2FF),
    bg: Color(0xFF08090D),
    bgTop: Color(0xFF0B0D12),
    surface: Color(0xD11A1C22),
    surfaceSolid: Color(0xFF16181E),
    surface2: Color(0xFF1B1E25),
    surface3: Color(0xFF222732),
    field: Color(0x0EFFFFFF),
    border: Color(0x14FFFFFF),
    line: Color(0x1AFFFFFF),
    glass: Color(0x9916181E),
    glassBorder: Color(0x1FFFFFFF),
    text: Color(0xFFEEF1F7),
    text2: Color(0xFFA4ADBD),
    text3: Color(0xFF6D7788),
    danger: Color(0xFFFF6B6B),
    dangerSoft: Color(0x1FFF6B6B),
    ok: Color(0xFF34D399),
    warn: Color(0xFFFBBF24),
    dock: Color(0x9414161C),
    dockBorder: Color(0x24FFFFFF),
    hero: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1F4FD8), Color(0xFF2F6BFF), Color(0xFF5B9BFF)],
      stops: [0, .55, 1],
    ),
    avatarGradients: _avatars,
  );

  static QColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTheme : light;

  LinearGradient get brandGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2F6BFF), Color(0xFF6AA8FF)],
      );

  LinearGradient get fabGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6AA8FF), Color(0xFF2F6BFF)],
      );

  LinearGradient get adminGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF173A86), Color(0xFF2F6BFF), Color(0xFF58A2FF)],
      );

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: dark ? const Color(0x59000000) : const Color(0x121E468C),
          blurRadius: dark ? 24 : 22,
          offset: const Offset(0, 8),
        ),
      ];

  List<BoxShadow> get brandShadow => [
        BoxShadow(
          color: brand.withOpacity(dark ? .42 : .32),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ];

  Color softOf(Color color, [double alpha = .12]) => color.withOpacity(alpha);
}
