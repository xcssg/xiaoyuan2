import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../theme/q_colors.dart';
import '../theme/q_utils.dart';

/* ============================================================
   背景
   ============================================================ */

class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: t.bg)),
        Positioned(
          left: -w * .45,
          top: -w * .55,
          width: w * 1.9,
          height: w * 1.15,
          child: _Glow(
            color: t.dark ? const Color(0xFF2F6BFF).withOpacity(.18) : const Color(0xFF5B9BFF).withOpacity(.30),
          ),
        ),
        Positioned(
          right: -w * .45,
          top: -w * .35,
          width: w * 1.5,
          height: w * 1.1,
          child: _Glow(
            color: t.dark ? const Color(0xFF7A54FF).withOpacity(.12) : const Color(0xFF8FC3FF).withOpacity(.26),
          ),
        ),
        Positioned(
          left: -w * .2,
          bottom: -h * .22,
          width: w * 1.4,
          height: w * 1.2,
          child: _Glow(
            color: t.dark ? const Color(0xFF234EB4).withOpacity(.16) : const Color(0xFFA8CEFF).withOpacity(.28),
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
          stops: const [0, .62],
        ),
      ),
    );
  }
}

/* ============================================================
   品牌标记
   ============================================================ */

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6AA8FF), Color(0xFF2F6BFF)],
        ),
        borderRadius: BorderRadius.circular(size * .32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F6BFF).withOpacity(.32),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * .6, size * .6),
          painter: _BrandMarkPainter(),
        ),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 32;
    canvas.scale(scale);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round;
    final wave = Path()
      ..moveTo(6.4, 20.6)
      ..cubicTo(8.9, 18.9, 10.8, 18.9, 13.1, 20.6)
      ..cubicTo(15.4, 22.3, 17.3, 22.3, 19.8, 20.6)
      ..cubicTo(21.8, 19.2, 23.4, 19.0, 24.6, 19.7);
    final arch = Path()
      ..moveTo(11.4, 15.5)
      ..cubicTo(11.4, 12.1, 13.6, 9.4, 16.5, 9.4)
      ..cubicTo(19.4, 9.4, 21.6, 12.1, 21.6, 15.5);
    canvas.drawPath(wave, paint);
    canvas.drawPath(arch, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GradientTitle extends StatelessWidget {
  const GradientTitle({super.key, required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => LinearGradient(
        colors: [t.brand, const Color(0xFF7BB6FF)],
      ).createShader(rect),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

/* ============================================================
   交互容器
   ============================================================ */

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = .975,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final HitTestBehavior behavior;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/* ============================================================
   基础组件
   ============================================================ */

class QAvatar extends StatelessWidget {
  const QAvatar({super.key, this.user, this.size = 40, this.anonymous = false, this.frame});

  final AppUser? user;
  final double size;
  final bool anonymous;
  final String? frame;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    final name = anonymous ? '匿' : (user?.nickname.isNotEmpty == true ? user!.nickname : '?');
    final idx = anonymous ? 5 : ((user?.avatar ?? 0) % t.avatarGradients.length);
    final initial = name.characters.first;
    final frameStyle = anonymous ? '' : (frame ?? user?.avatarFrame ?? '');
    final hasFrame = frameStyle.isNotEmpty;
    final innerSize = hasFrame ? size - 5 : size;

    final avatar = Container(
      width: innerSize,
      height: innerSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: t.avatarGradients[idx],
        border: Border.all(color: Colors.white.withOpacity(.28)),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: innerSize * .4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (!hasFrame) return avatar;

    final ring = _frameRing(frameStyle);
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ring,
        boxShadow: [
          BoxShadow(
            color: (ring.colors.first).withOpacity(.32),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: avatar,
    );
  }
}

LinearGradient _frameRing(String frame) {
  switch (frame) {
    case 'gold':
      return const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFF5B301), Color(0xFFD97706)]);
    case 'neon':
      return const LinearGradient(colors: [Color(0xFF22D3EE), Color(0xFFA855F7)]);
    case 'sakura':
      return const LinearGradient(colors: [Color(0xFFFF9AC1), Color(0xFFFFD1E3)]);
    case 'tech':
      return const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF22D3EE)]);
    default:
      return const LinearGradient(colors: [Color(0xFF93C5FD), Color(0xFF2F6BFF)]);
  }
}

class QTitleBadge extends StatelessWidget {
  const QTitleBadge({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxWidth: 96),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF3C4), Color(0xFFFFE08A)]),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFF5B301).withOpacity(.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded, size: 10, color: Color(0xFFB45309)),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A4B08),
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum QPillStyle { brand, soft, danger, ok }

class QPill extends StatelessWidget {
  const QPill({
    super.key,
    required this.text,
    this.style = QPillStyle.brand,
    this.icon,
  });

  final String text;
  final QPillStyle style;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    Color bg;
    Color fg;
    switch (style) {
      case QPillStyle.brand:
        bg = t.brand.withOpacity(.10);
        fg = t.dark ? t.brand2 : t.brandInk;
        break;
      case QPillStyle.soft:
        bg = t.field;
        fg = t.text2;
        break;
      case QPillStyle.danger:
        bg = t.dangerSoft;
        fg = t.danger;
        break;
      case QPillStyle.ok:
        bg = t.ok.withOpacity(.12);
        fg = t.ok;
        break;
    }
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class QCard extends StatelessWidget {
  const QCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.color,
    this.borderColor,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? t.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? t.border),
        boxShadow: shadow ? t.cardShadow : null,
      ),
      child: child,
    );
  }
}

class QIconButton extends StatelessWidget {
  const QIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
    this.accent = false,
    this.size = 38,
    this.iconSize = 18,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final bool accent;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: .92,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: t.surface,
          border: Border.all(color: t.border),
          boxShadow: t.cardShadow,
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: color ?? (accent ? t.brand : t.text2),
        ),
      ),
    );
  }
}

enum QButtonStyle { primary, ghost, danger }

class QButton extends StatelessWidget {
  const QButton({
    super.key,
    required this.label,
    this.onTap,
    this.style = QButtonStyle.primary,
    this.icon,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onTap;
  final QButtonStyle style;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    final isPrimary = style == QButtonStyle.primary;
    final isDanger = style == QButtonStyle.danger;
    final fg = isPrimary || isDanger ? Colors.white : t.text;
    return Pressable(
      onTap: onTap,
      scale: .98,
      child: Container(
        height: height,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? t.brandGradient
              : isDanger
                  ? const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFFF7A7A)],
                    )
                  : null,
          color: isPrimary || isDanger ? null : t.field,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary || isDanger ? null : Border.all(color: t.border),
          boxShadow: isPrimary
              ? t.brandShadow
              : isDanger
                  ? [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(.28),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      )
                    ]
                  : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: fg),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QTextButton extends StatelessWidget {
  const QTextButton({super.key, required this.label, this.onTap, this.color});

  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color ?? t.brand,
          ),
        ),
      ),
    );
  }
}

class QSectionHead extends StatelessWidget {
  const QSectionHead({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: t.text,
              letterSpacing: -.2,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class QEmptyState extends StatelessWidget {
  const QEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.desc,
    this.action,
  });

  final IconData icon;
  final String title;
  final String desc;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: t.brand.withOpacity(.08),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, size: 26, color: t.brand),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: t.text2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: t.text3),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            action!,
          ],
        ],
      ),
    );
  }
}

class QDivider extends StatelessWidget {
  const QDivider({super.key, this.margin = EdgeInsets.zero});

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Container(
      height: 1,
      margin: margin,
      color: t.line,
    );
  }
}

/* ============================================================
   顶栏
   ============================================================ */

class QTopBar extends StatelessWidget {
  const QTopBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.large = true,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Container(
      color: t.bgTop.withOpacity(.94),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (subtitle != null) ...[
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: t.text2,
                      letterSpacing: .2,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                if (title != null)
                  Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: large ? 23 : 17,
                      fontWeight: large ? FontWeight.w700 : FontWeight.w600,
                      height: 1.2,
                      letterSpacing: -.4,
                      color: t.text,
                    ),
                  ),
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  actions[i],
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/* ============================================================
   芯片 / 分段控件 / 开关
   ============================================================ */

class QChip extends StatelessWidget {
  const QChip({
    super.key,
    required this.label,
    this.icon,
    this.active = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    final fg = active
        ? (t.dark ? const Color(0xFF061024) : Colors.white)
        : t.text2;
    return Pressable(
      onTap: onTap,
      scale: .96,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          gradient: active ? t.brandGradient : null,
          color: active ? null : t.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: active ? Colors.transparent : t.border),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: t.brand.withOpacity(.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: fg,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QSegOption {
  const QSegOption(this.value, this.label);

  final String value;
  final String label;
}

class QSeg extends StatelessWidget {
  const QSeg({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<QSegOption> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.field,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: Pressable(
                onTap: () => onChanged(option.value),
                scale: .97,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: option.value == value
                        ? (t.dark ? const Color(0xFF262B35) : t.surfaceSolid)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: option.value == value && !t.dark
                        ? [
                            BoxShadow(
                              color: const Color(0x1A102E60),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: option.value == value
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: option.value == value ? t.text : t.text2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class QSwitch extends StatelessWidget {
  const QSwitch({super.key, required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          gradient: on ? t.brandGradient : null,
          color: on ? null : t.line,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.22),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   输入
   ============================================================ */

class QField extends StatelessWidget {
  const QField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.maxLength,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      maxLength: maxLength,
      autofocus: autofocus,
      style: TextStyle(fontSize: 15, color: t.text),
      cursorColor: t.brand,
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: t.text3),
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: 18, color: t.text3),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 20),
        filled: true,
        fillColor: t.field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: t.brand.withOpacity(.45)),
        ),
      ),
    );
  }
}

class QTextArea extends StatelessWidget {
  const QTextArea({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLength = 1000,
    this.minHeight = 148,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: null,
      minLines: 5,
      style: TextStyle(fontSize: 14.5, height: 1.7, color: t.text),
      cursorColor: t.brand,
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: t.text3),
        filled: true,
        fillColor: t.field,
        contentPadding: const EdgeInsets.all(14),
        constraints: BoxConstraints(minHeight: minHeight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: t.brand.withOpacity(.45)),
        ),
      ),
    );
  }
}

class QSearchField extends StatelessWidget {
  const QSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onSubmitted,
    this.autofocus = false,
    this.height = 40,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.field,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 16, color: t.text3),
          const SizedBox(width: 7),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: onSubmitted,
              autofocus: autofocus,
              style: TextStyle(fontSize: 12.5, color: t.text),
              cursorColor: t.brand,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(fontSize: 12.5, color: t.text3),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   帖子 / 贴吧
   ============================================================ */

class QPostCard extends StatelessWidget {
  const QPostCard({super.key, required this.post, required this.onTap});

  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    final store = AppScope.of(context).store;
    final bar = store.bar(post.barId);
    final mod = store.moduleOf(bar?.module ?? 'lost');
    final author = store.getUser(post.authorId);
    final displayName = post.anonymous ? '匿名同学' : (author?.nickname ?? '已注销用户');
    final nameColor = post.anonymous ? null : parseHexColor(author?.nameColor ?? '');
    final liked = store.isLiked(post.id);
    return Pressable(
      onTap: onTap,
      scale: .985,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: t.border),
          boxShadow: t.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                QAvatar(user: author, size: 38, anonymous: post.anonymous),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: nameColor ?? t.text,
                              ),
                            ),
                          ),
                          if (post.anonymous) ...[
                            const SizedBox(width: 5),
                            const QPill(text: '匿名', style: QPillStyle.soft),
                          ],
                          if (!post.anonymous && author != null && author.title.isNotEmpty) ...[
                            const SizedBox(width: 5),
                            QTitleBadge(title: author.title),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              bar?.name ?? '未知贴吧',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10.5, color: t.text3),
                            ),
                          ),
                          const _MetaDot(),
                          Text(
                            timeAgo(post.createdAt),
                            style: TextStyle(fontSize: 10.5, color: t.text3),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: mod.color.withOpacity(.10),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    mod.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: mod.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                height: 1.45,
                letterSpacing: -.1,
                color: t.text,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              post.content.replaceAll('\n', ' '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.65,
                color: t.text2,
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: t.line),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 13,
                  color: liked ? t.danger : t.text3,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.likes}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: liked ? t.danger : t.text3,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.chat_bubble_outline_rounded, size: 13, color: t.text3),
                const SizedBox(width: 4),
                Text(
                  '${post.comments.length}',
                  style: TextStyle(fontSize: 11.5, color: t.text3),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, size: 14, color: t.text3.withOpacity(.6)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaDot extends StatelessWidget {
  const _MetaDot();

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Container(
      width: 2,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: t.text3,
        shape: BoxShape.circle,
      ),
    );
  }
}

class QBarIcon extends StatelessWidget {
  const QBarIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
    this.iconSize = 23,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(size * .33),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

class QBarRow extends StatelessWidget {
  const QBarRow({super.key, required this.bar, required this.onTap});

  final DiscussionBar bar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    final store = AppScope.of(context).store;
    final mod = store.moduleOf(bar.module);
    return Pressable(
      onTap: onTap,
      scale: .985,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: t.border),
          boxShadow: t.cardShadow,
        ),
        child: Row(
          children: [
            QBarIcon(icon: qIcon(bar.icon), color: mod.color),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          bar.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: t.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      QPill(text: mod.name, style: QPillStyle.soft),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    bar.desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: t.text3),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      _BarStat(value: '${store.countPosts(bar.id)}', label: '帖子'),
                      const SizedBox(width: 12),
                      _BarStat(value: '${store.memberCount(bar.id)}', label: '位同学'),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: t.text3),
          ],
        ),
      ),
    );
  }
}

class _BarStat extends StatelessWidget {
  const _BarStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: t.text2,
            ),
          ),
          TextSpan(text: ' $label'),
        ],
      ),
      style: TextStyle(fontSize: 10.5, color: t.text3),
    );
  }
}

/* ============================================================
   Dock / Toast
   ============================================================ */

class QDock extends StatelessWidget {
  const QDock({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    final route = app.route;
    final unread = app.store.unreadCount;
    int activeIndex = -1;
    if (route.name == 'home') activeIndex = 0;
    if (route.name == 'bars' || route.name == 'bar' || route.name == 'search') activeIndex = 1;
    if (route.name == 'messages') activeIndex = 2;
    if (route.name == 'me') activeIndex = 3;

    return SizedBox(
      height: 77,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 68,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: t.dark
                        ? Colors.black.withOpacity(.55)
                        : const Color(0x2E16346E),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.dock,
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(color: t.dockBorder),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 68,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 80) / 4;
                final indicatorLeft = activeIndex < 0
                    ? null
                    : 10 + activeIndex * itemWidth + (activeIndex >= 2 ? 60 : 0);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (indicatorLeft != null)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        left: indicatorLeft,
                        top: 9,
                        width: itemWidth,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            color: t.brand.withOpacity(t.dark ? .14 : .10),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: t.brand.withOpacity(.08)),
                            boxShadow: [
                              BoxShadow(
                                color: t.brand.withOpacity(.10),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          _DockItem(
                            icon: Icons.home_outlined,
                            filledIcon: Icons.home_rounded,
                            label: '首页',
                            active: activeIndex == 0,
                            onTap: () => app.navigate(AppRoute.home),
                          ),
                          _DockItem(
                            icon: Icons.explore_outlined,
                            filledIcon: Icons.explore_rounded,
                            label: '贴吧',
                            active: activeIndex == 1,
                            onTap: () => app.navigate(AppRoute.bars),
                          ),
                          const SizedBox(width: 4),
                          Pressable(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              app.navigate(AppRoute.compose);
                            },
                            scale: .93,
                            child: Transform.translate(
                              offset: const Offset(0, -9),
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: t.fabGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: t.brand.withOpacity(.45),
                                      blurRadius: 22,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.add_rounded, size: 26, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _DockItem(
                            icon: Icons.chat_bubble_outline_rounded,
                            filledIcon: Icons.chat_bubble_rounded,
                            label: '消息',
                            active: activeIndex == 2,
                            unread: unread > 0,
                            onTap: () => app.navigate(AppRoute.messages),
                          ),
                          _DockItem(
                            icon: Icons.person_outline_rounded,
                            filledIcon: Icons.person_rounded,
                            label: '我的',
                            active: activeIndex == 3,
                            onTap: () => app.navigate(AppRoute.me),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.filledIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.unread = false,
  });

  final IconData icon;
  final IconData filledIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    final fg = active ? (t.dark ? t.brand2 : t.brand) : t.text3;
    return Expanded(
      child: Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        scale: .92,
        child: Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: active ? 1.10 : 1,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Icon(active ? filledIcon : icon, size: 21, color: fg),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(fontSize: 9, color: fg, letterSpacing: .3),
                    child: Text(label),
                  ),
                ],
              ),
              if (unread)
                Positioned(
                  top: 8,
                  right: 18,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: t.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.dock.withOpacity(.9), width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class QToastLayer extends StatelessWidget {
  const QToastLayer({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    if (app.toasts.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final toast in app.toasts)
              TweenAnimationBuilder<double>(
                key: ValueKey(toast.id),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 10),
                    child: child,
                  ),
                ),
                child: _ToastCard(data: toast),
              ),
          ],
        ),
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.data});

  final QToastData data;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    final isSuccess = data.type == ToastType.success;
    final isError = data.type == ToastType.error;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xE6101A2A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.34),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSuccess ? Icons.check_rounded : Icons.info_outline_rounded,
            size: 16,
            color: isError ? const Color(0xFFFF8B8B) : (isSuccess ? const Color(0xFF4ADE80) : Colors.white70),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              data.message,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
