import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/pokebinder_theme.dart';

class PokeballPainter extends CustomPainter {
  final double open;
  final double glow;

  const PokeballPainter({this.open = 0, this.glow = 0});

  static const _ink = PokeBinderColors.ink;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2;
    final c = size.center(Offset.zero);
    final bandHalf = r * 0.085;
    final stroke = r * 0.075;

    final circle = Path()
      ..addOval(Rect.fromCircle(center: c, radius: r - stroke / 2));
    final topArea = Path()
      ..addRect(Rect.fromLTRB(c.dx - r, c.dy - r, c.dx + r, c.dy));
    final bottomArea = Path()
      ..addRect(Rect.fromLTRB(c.dx - r, c.dy, c.dx + r, c.dy + r));
    final topHalf = Path.combine(PathOperation.intersect, circle, topArea);
    final bottomHalf = Path.combine(PathOperation.intersect, circle, bottomArea);

    final ballRect = Rect.fromCircle(center: c, radius: r);

    canvas.save();
    canvas.translate(0, open * r * 0.14);
    _drawHalf(
      canvas,
      half: bottomHalf,
      ballRect: ballRect,
      c: c,
      r: r,
      bandHalf: bandHalf,
      stroke: stroke,
      top: false,
    );
    canvas.restore();

    canvas.save();
    final pivot = Offset(c.dx + r * 0.92, c.dy);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(open * 0.62);
    canvas.translate(-pivot.dx, -pivot.dy);
    canvas.translate(0, -open * r * 0.34);
    _drawHalf(
      canvas,
      half: topHalf,
      ballRect: ballRect,
      c: c,
      r: r,
      bandHalf: bandHalf,
      stroke: stroke,
      top: true,
    );
    canvas.restore();

    final buttonScale = (1 - open * 4).clamp(0.0, 1.0).toDouble();
    if (buttonScale > 0) {
      _drawButton(canvas, c, r, buttonScale);
    }
  }

  void _drawHalf(
    Canvas canvas, {
    required Path half,
    required Rect ballRect,
    required Offset c,
    required double r,
    required double bandHalf,
    required double stroke,
    required bool top,
  }) {
    canvas.save();
    canvas.clipPath(half);

    final fill = Paint()
      ..shader = (top
              ? const RadialGradient(
                  center: Alignment(-0.45, -0.6),
                  radius: 1.15,
                  colors: [
                    Color(0xFFF0674F),
                    PokeBinderColors.red,
                    PokeBinderColors.redDeep,
                  ],
                  stops: [0, 0.5, 1],
                )
              : const RadialGradient(
                  center: Alignment(-0.35, 0.5),
                  radius: 1.2,
                  colors: [
                    PokeBinderColors.white,
                    Color(0xFFF1EADA),
                    Color(0xFFD3C8AF),
                  ],
                  stops: [0, 0.55, 1],
                ))
          .createShader(ballRect);
    canvas.drawRect(ballRect, fill);

    final band = Paint()..color = _ink;
    canvas.drawRect(
      top
          ? Rect.fromLTRB(c.dx - r, c.dy - bandHalf, c.dx + r, c.dy)
          : Rect.fromLTRB(c.dx - r, c.dy, c.dx + r, c.dy + bandHalf),
      band,
    );

    if (top) {
      final shine = Paint()
        ..color = PokeBinderColors.white.withValues(alpha: 0.38)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.075;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.72),
        math.pi * 1.08,
        math.pi * 0.3,
        false,
        shine,
      );
    }
    canvas.restore();

    canvas.drawPath(
      half,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke,
    );
  }

  void _drawButton(Canvas canvas, Offset c, double r, double scale) {
    final outer = r * 0.30 * scale;
    final inner = r * 0.19 * scale;

    if (glow > 0) {
      final glowRadius = r * (0.35 + 0.95 * glow) * scale;
      canvas.drawCircle(
        c,
        glowRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              PokeBinderColors.gold.withValues(alpha: 0.85 * glow),
              PokeBinderColors.gold.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: glowRadius)),
      );
    }

    canvas.drawCircle(c, outer, Paint()..color = _ink);
    canvas.drawCircle(
      c,
      inner,
      Paint()
        ..color = Color.lerp(
          PokeBinderColors.white,
          const Color(0xFFFFF1C2),
          glow,
        )!,
    );
    canvas.drawCircle(
      c,
      inner,
      Paint()
        ..color = _ink.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.03 * scale,
    );
  }

  @override
  bool shouldRepaint(PokeballPainter oldDelegate) =>
      oldDelegate.open != open || oldDelegate.glow != glow;
}

class PokeballGlyphPainter extends CustomPainter {
  final Color color;
  final double strokeFraction;
  final double rotation;

  const PokeballGlyphPainter({
    required this.color,
    this.strokeFraction = 0.11,
    this.rotation = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final stroke = size.shortestSide * strokeFraction;
    final r = size.shortestSide / 2 - stroke / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rotation);
    canvas.translate(-c.dx, -c.dy);

    canvas.drawCircle(c, r, paint);
    final buttonRadius = r * 0.3;
    canvas.drawLine(
      Offset(c.dx - r, c.dy),
      Offset(c.dx - buttonRadius, c.dy),
      paint,
    );
    canvas.drawLine(
      Offset(c.dx + buttonRadius, c.dy),
      Offset(c.dx + r, c.dy),
      paint,
    );
    canvas.drawCircle(c, buttonRadius, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(PokeballGlyphPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeFraction != strokeFraction ||
      oldDelegate.rotation != rotation;
}

class PokeballIcon extends StatelessWidget {
  final double size;

  const PokeballIcon({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: PokeballPainter()),
    );
  }
}

class PokeballSpinner extends StatefulWidget {
  final double size;
  final Color color;

  const PokeballSpinner({
    super.key,
    this.size = 16,
    this.color = PokeBinderColors.white,
  });

  @override
  State<PokeballSpinner> createState() => _PokeballSpinnerState();
}

class _PokeballSpinnerState extends State<PokeballSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: PokeballGlyphPainter(
            color: widget.color,
            rotation: Curves.easeInOut.transform(_controller.value) *
                2 *
                math.pi,
          ),
        ),
      ),
    );
  }
}

class PokeballLoader extends StatefulWidget {
  final double size;
  final String? label;

  const PokeballLoader({super.key, this.size = 64, this.label});

  @override
  State<PokeballLoader> createState() => _PokeballLoaderState();
}

class _PokeballLoaderState extends State<PokeballLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final label = widget.label;

    return Semantics(
      label: label ?? 'Loading',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;

              final wobble = (t / 0.55).clamp(0.0, 1.0);
              final angle = t < 0.55
                  ? math.sin(wobble * math.pi * 4) * 0.32 * (1 - wobble * 0.4)
                  : 0.0;
              final glowPhase = ((t - 0.55) / 0.25).clamp(0.0, 1.0);
              final glow = math.sin(glowPhase * math.pi);
              final lean = angle.abs() / 0.32;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: size,
                    height: size,
                    child: Transform.rotate(
                      angle: angle,
                      alignment: const Alignment(0, 0.85),
                      child: CustomPaint(painter: PokeballPainter(glow: glow)),
                    ),
                  ),
                  SizedBox(height: size * 0.08),
                  Container(
                    width: size * (0.62 - 0.1 * lean),
                    height: size * 0.07,
                    decoration: BoxDecoration(
                      color: PokeBinderColors.ink.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(size),
                    ),
                  ),
                ],
              );
            },
          ),
          if (label != null) ...[
            const SizedBox(height: PokeBinderSpacing.sp4),
            Text(label, style: PokeBinderText.sectionLabel),
          ],
        ],
      ),
    );
  }
}

class PokeballBadge extends StatefulWidget {
  final double size;
  final Duration initialDelay;

  const PokeballBadge({
    super.key,
    this.size = 60,
    this.initialDelay = const Duration(milliseconds: 750),
  });

  @override
  State<PokeballBadge> createState() => _PokeballBadgeState();
}

class _PokeballBadgeState extends State<PokeballBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.initialDelay, _wobble);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _wobble() {
    if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return GestureDetector(
      onTap: _wobble,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final p = _controller.value;
          final angle = math.sin(p * math.pi * 4) * 0.34 * (1 - p);
          final glow = math.sin(((p - 0.55) / 0.3).clamp(0.0, 1.0) * math.pi);
          return Transform.rotate(
            angle: angle,
            alignment: const Alignment(0, 0.85),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: PokeBinderColors.ink.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CustomPaint(painter: PokeballPainter(glow: glow)),
            ),
          );
        },
      ),
    );
  }
}

Path sparklePath(Offset center, double radius) {
  final path = Path();
  const points = 4;
  for (var i = 0; i < points * 2; i++) {
    final isOuter = i.isEven;
    final rad = isOuter ? radius : radius * 0.32;
    final angle = -math.pi / 2 + i * math.pi / points;
    final p = Offset(
      center.dx + math.cos(angle) * rad,
      center.dy + math.sin(angle) * rad,
    );
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  return path..close();
}
