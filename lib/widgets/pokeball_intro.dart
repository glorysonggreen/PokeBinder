import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/pokebinder_motion.dart';
import '../theme/pokebinder_theme.dart';
import 'pokeball.dart';
import '../services/audio_service.dart';

class PokeBinderIntro extends StatefulWidget {
  final Widget child;

  const PokeBinderIntro({super.key, required this.child});

  @override
  State<PokeBinderIntro> createState() => _PokeBinderIntroState();
}

class _PokeBinderIntroState extends State<PokeBinderIntro>
    with TickerProviderStateMixin {
  static bool _hasPlayed = false;

  static const _childKey = ValueKey('intro-child');
  static const _overlayKey = ValueKey('intro-overlay');

  late final AnimationController _timeline = AnimationController(
    vsync: this,
    duration: PokeBinderMotion.intro,
  );
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  bool _initialised = false;
  bool _showChild = false;
  bool _finished = false;
  bool _exiting = false;

  double get _totalMs => PokeBinderMotion.intro.inMilliseconds.toDouble();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;

    if (_hasPlayed || MediaQuery.disableAnimationsOf(context)) {
      _showChild = true;
      _finished = true;
      return;
    }
    _hasPlayed = true;
    _timeline.addStatusListener((status) {
      if (status == AnimationStatus.completed) _beginExit();
    });
    _timeline.forward();

    PokeBinderAudio.play(Sfx.intro);
  }

  @override
  void dispose() {
    _timeline.dispose();
    _exit.dispose();
    super.dispose();
  }

  void _beginExit({bool skipped = false}) {
    if (_exiting || !mounted) return;
    _exiting = true;
    if (skipped) {
      PokeBinderAudio.stop(Sfx.intro);
      _timeline.stop();
      _exit.duration = const Duration(milliseconds: 320);
    }
    setState(() => _showChild = true);
    _exit.forward().whenComplete(() {
      if (mounted) setState(() => _finished = true);
    });
  }

  double _seg(double startMs, double endMs, [Curve curve = Curves.linear]) {
    final raw = (_timeline.value * _totalMs - startMs) / (endMs - startMs);
    return curve.transform(raw.clamp(0.0, 1.0).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_showChild)
          KeyedSubtree(key: _childKey, child: widget.child),
        if (!_finished)
          AnimatedBuilder(
            key: _overlayKey,
            animation: _exit,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _beginExit(skipped: true),
              child: _buildScene(context),
            ),
            builder: (context, scene) {
              final t = Curves.easeIn.transform(_exit.value);
              return IgnorePointer(
                ignoring: _exit.value > 0,
                child: Opacity(
                  opacity: 1 - t,
                  child: Transform.scale(scale: 1 + 0.06 * t, child: scene),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildScene(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final ballSize = math.min(shortest * 0.34, 148.0);

    return Material(
      color: PokeBinderColors.cream,
      child: AnimatedBuilder(
        animation: _timeline,
        builder: (context, _) {
          final drop = _seg(0, 450, Curves.bounceOut);
          final fadeIn = _seg(0, 180);
          final wobbleP = _seg(500, 1200);
          final angle = math.sin(wobbleP * math.pi * 4) * 0.34 * (1 - wobbleP);
          final glow = _seg(1200, 1380, Curves.easeOut) *
              (1 - _seg(1500, 1900, Curves.easeIn));
          final open = _seg(1380, 1800, Curves.easeOutCubic);
          final burst = _seg(1380, 2150, Curves.easeOutCubic);
          final word = _seg(1520, 2150, Curves.easeOutCubic);
          final shine = _seg(1950, 2500, Curves.easeInOut);
          final hint = _seg(500, 900) * (1 - _seg(1300, 1500));

          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.15),
                    radius: 0.95,
                    colors: [PokeBinderColors.white, PokeBinderColors.cream],
                  ),
                ),
              ),
              Opacity(
                opacity: 0.06 + 0.04 * open,
                child: Transform.scale(
                  scale: 1.3,
                  child: CustomPaint(
                    painter: PokeballGlyphPainter(
                      color: PokeBinderColors.ink,
                      strokeFraction: 0.05,
                      rotation: _timeline.value * 0.9,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBall(
                      ballSize: ballSize,
                      drop: drop,
                      fadeIn: fadeIn,
                      angle: angle,
                      glow: glow,
                      open: open,
                      burst: burst,
                    ),
                    SizedBox(height: ballSize * 0.34),
                    _buildWordmark(word: word, shine: shine),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 28 + MediaQuery.paddingOf(context).bottom,
                child: Opacity(
                  opacity: hint * 0.55,
                  child: Text(
                    'TAP TO SKIP',
                    textAlign: TextAlign.center,
                    style: PokeBinderText.sectionLabel,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBall({
    required double ballSize,
    required double drop,
    required double fadeIn,
    required double angle,
    required double glow,
    required double open,
    required double burst,
  }) {
    final dropDistance = ballSize * 2.2;

    return SizedBox.square(
      dimension: ballSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (open > 0)
            Positioned(
              left: -ballSize,
              top: -ballSize,
              width: ballSize * 3,
              height: ballSize * 3,
              child: IgnorePointer(
                child: Opacity(
                  opacity: (open * (1 - 0.55 * burst)).clamp(0.0, 1.0).toDouble(),
                  child: Transform.scale(
                    scale: 0.45 + 0.55 * open,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xE6FFFFFF),
                            Color(0x80F6D68B),
                            Color(0x00E8AC3E),
                          ],
                          stops: [0, 0.35, 1],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: ballSize * (0.5 - 0.3 * drop),
            right: ballSize * (0.5 - 0.3 * drop),
            bottom: -ballSize * 0.1,
            height: ballSize * 0.08,
            child: Opacity(
              opacity: fadeIn * 0.9 * (1 - 0.5 * open),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: PokeBinderColors.ink.withValues(alpha: 0.14 * drop),
                  borderRadius: BorderRadius.circular(ballSize),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: fadeIn,
              child: Transform.translate(
                offset: Offset(0, -(1 - drop) * dropDistance),
                child: Transform.rotate(
                  angle: angle,
                  alignment: const Alignment(0, 0.85),
                  child: CustomPaint(
                    painter: PokeballPainter(open: open, glow: glow),
                  ),
                ),
              ),
            ),
          ),
          if (burst > 0 && burst < 1)
            Positioned(
              left: -ballSize,
              top: -ballSize,
              width: ballSize * 3,
              height: ballSize * 3,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _BurstPainter(progress: burst, ballRadius: ballSize / 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWordmark({required double word, required double shine}) {
    final rise = Curves.easeOutBack.transform(word);
    final visible = word.clamp(0.0, 1.0).toDouble();
    final style = PokeBinderText.chakraPetch(TextStyle(
      fontSize: 38,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2 + (1 - word) * 7,
      color: PokeBinderColors.ink,
    ));

    return Opacity(
      opacity: visible,
      child: Transform.translate(
        offset: Offset(0, (1 - rise) * 22),
        child: Transform.scale(
          scale: 0.9 + 0.1 * rise,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment(-2.4 + 4.8 * shine, -0.4),
                  end: Alignment(-1.4 + 4.8 * shine, 0.4),
                  colors: const [
                    Color(0x00FFFFFF),
                    Color(0xCCFFF1C2),
                    Color(0x00FFFFFF),
                  ],
                ).createShader(bounds),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Poké',
                        style: style.copyWith(color: PokeBinderColors.red),
                      ),
                      Text('Binder', style: style),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),
              Container(
                width: 64 * visible,
                height: 4,
                decoration: BoxDecoration(
                  gradient: PokeBinderColors.goldGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),
              Text('YOUR POKÉMON TCG COLLECTION', style: PokeBinderText.eyebrow),
            ],
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final double progress;
  final double ballRadius;

  const _BurstPainter({required this.progress, required this.ballRadius});

  static const _colors = [
    PokeBinderColors.gold,
    PokeBinderColors.white,
    PokeBinderColors.goldDeep,
    PokeBinderColors.teal,
    PokeBinderColors.red,
  ];
  static const _count = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final fade = (1 - progress).clamp(0.0, 1.0).toDouble();

    canvas.drawCircle(
      c,
      ballRadius * (0.6 + 1.9 * progress),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ballRadius * 0.09 * fade
        ..color = PokeBinderColors.gold.withValues(alpha: 0.7 * fade),
    );

    for (var i = 0; i < _count; i++) {
      final angle = i * 2 * math.pi / _count + (i.isOdd ? 0.14 : -0.06);
      final reach = ballRadius * (1.25 + 0.5 * ((i * 7) % 5) / 4);
      final start = ballRadius * 0.35;
      final dist = start + (reach - start) * progress;
      final center = c + Offset(math.cos(angle), math.sin(angle)) * dist;
      final radius = ballRadius * (i.isEven ? 0.2 : 0.13) * (1 - progress * 0.6);

      canvas.drawPath(
        sparklePath(center, radius),
        Paint()
          ..color = _colors[i % _colors.length].withValues(alpha: fade),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.ballRadius != ballRadius;
}
