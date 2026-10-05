import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/audio_service.dart';

/// A card you can drag to tilt and spin.
///
/// On release it springs back to rest. While tilted, a holographic foil sheen
/// and a specular glint slide across the front face, like a real holo card
/// catching the light. Set [holo] to false to turn the sheen off.
class Interactive3DCard extends StatefulWidget {
  final Widget child;
  final Widget? back;
  final double maxVerticalTilt;
  final double horizontalSensitivity;
  final double verticalSensitivity;

  /// Whether to draw the holographic sheen over the front face.
  final bool holo;

  /// Corner radius of the card as a fraction of its width, so the sheen is
  /// clipped to the card's shape. Matches the card art.
  final double cornerRadiusFraction;

  const Interactive3DCard({
    super.key,
    required this.child,
    this.back,
    this.maxVerticalTilt = 0.30,
    this.horizontalSensitivity = 0.010,
    this.verticalSensitivity = 0.012,
    this.holo = true,
    this.cornerRadiusFraction = 0.045,
  });

  @override
  State<Interactive3DCard> createState() => _Interactive3DCardState();
}

class _Interactive3DCardState extends State<Interactive3DCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  double _rotationX = 0;
  double _rotationY = 0;
  double _fromX = 0;
  double _fromY = 0;
  double _toX = 0;
  double _toY = 0;

  Curve _curve = Curves.easeOutCubic;
  VoidCallback? _onDone;

  bool _dragActive = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )
      ..addListener(_onAnimationTick)
      ..addStatusListener(_onStatus);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onAnimationTick)
      ..removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    final t = _curve.transform(_controller.value);
    setState(() {
      _rotationX = _lerp(_fromX, _toX, t);
      _rotationY = _lerp(_fromY, _toY, t);
    });
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final done = _onDone;
    _onDone = null;
    done?.call();
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _clampTilt(double value) {
    return value.clamp(-widget.maxVerticalTilt, widget.maxVerticalTilt);
  }

  void _animateTo({
    required double toX,
    required double toY,
    Curve curve = Curves.easeOutCubic,
    Duration duration = const Duration(milliseconds: 450),
    VoidCallback? onDone,
  }) {
    _fromX = _rotationX;
    _fromY = _rotationY;
    _toX = toX;
    _toY = toY;
    _curve = curve;
    _onDone = onDone;
    _controller
      ..stop()
      ..duration =
          MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration
      ..value = 0
      ..forward();
  }

  /// Springs back to rest with a little overshoot, like a card settling.
  void _settle() {
    _animateTo(
      toX: 0,
      toY: 0,
      curve: Curves.elasticOut,
      duration: const Duration(milliseconds: 750),
    );
  }

  void _handlePanStart(DragStartDetails details) {
    _controller.stop();
    _onDone = null;
    _dragActive = true;
    if (widget.holo) PokeBinderAudio.play(Sfx.foil);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _rotationY += details.delta.dx * widget.horizontalSensitivity;
      _rotationX = _clampTilt(
        _rotationX - details.delta.dy * widget.verticalSensitivity,
      );
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    _dragActive = false;
    _settle();
  }

  void _handleTap() {
    if (_dragActive) return;
    if (widget.holo) PokeBinderAudio.play(Sfx.foil);
    final peekY = _rotationY == 0 ? 0.18 : _rotationY * 1.3;
    _animateTo(
      toX: 0,
      toY: peekY,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 240),
      onDone: _settle,
    );
  }

  bool get _isShowingBack {
    if (widget.back == null) return false;
    final twoPi = 2 * math.pi;
    var normalized = _rotationY % twoPi;
    if (normalized < 0) normalized += twoPi;
    return normalized > math.pi / 2 && normalized < 3 * math.pi / 2;
  }

  @override
  Widget build(BuildContext context) {
    final showBack = _isShowingBack;
    final effectiveRotationY = _rotationY + (showBack ? math.pi : 0);
    final matrix = Matrix4.identity()

      ..setEntry(3, 2, 0.0012)
      ..rotateX(_rotationX)
      ..rotateY(effectiveRotationY);

    final front = widget.holo
        ? Stack(
            fit: StackFit.passthrough,
            children: [
              widget.child,
              Positioned.fill(
                child: IgnorePointer(
                  child: _HoloSheen(
                    rotationX: _rotationX,
                    rotationY: _rotationY,
                    cornerRadiusFraction: widget.cornerRadiusFraction,
                  ),
                ),
              ),
            ],
          )
        : widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onTap: _handleTap,
      child: Transform(
        alignment: Alignment.center,
        transform: matrix,
        child: showBack ? widget.back : front,
      ),
    );
  }
}

/// Rainbow foil + specular glint that move with the card's tilt. Invisible
/// while the card is at rest and fades in as it tilts.
class _HoloSheen extends StatelessWidget {
  final double rotationX;
  final double rotationY;
  final double cornerRadiusFraction;

  const _HoloSheen({
    required this.rotationX,
    required this.rotationY,
    required this.cornerRadiusFraction,
  });

  @override
  Widget build(BuildContext context) {
    final sway = math.sin(rotationY);
    final intensity =
        ((sway.abs() + rotationX.abs() * 1.4) * 1.7).clamp(0.0, 1.0).toDouble();
    if (intensity < 0.01) return const SizedBox.shrink();

    // The foil band slides across the card as it turns.
    final shift = sway * 1.4 - rotationX * 1.2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0;
        final radius = width * cornerRadiusFraction;

        Color tone(Color color, double alpha) =>
            color.withValues(alpha: alpha * intensity);

        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.4 + shift, -1),
                    end: Alignment(0.2 + shift, 1),
                    colors: [
                      tone(const Color(0xFFFFFFFF), 0),
                      tone(const Color(0xFF8FD0D8), 0.30),
                      tone(const Color(0xFFF6D68B), 0.34),
                      tone(const Color(0xFFE8788C), 0.28),
                      tone(const Color(0xFFB9A2F0), 0.26),
                      tone(const Color(0xFFFFFFFF), 0),
                    ],
                    stops: const [0, 0.22, 0.42, 0.6, 0.78, 1],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      (-sway * 1.3).clamp(-1.0, 1.0).toDouble(),
                      (rotationX * 3).clamp(-1.0, 1.0).toDouble() - 0.2,
                    ),
                    radius: 0.75,
                    colors: [
                      tone(const Color(0xFFFFFFFF), 0.42),
                      tone(const Color(0xFFFFFFFF), 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
