import 'dart:math' as math;
import 'package:flutter/material.dart';

class Interactive3DCard extends StatefulWidget {
  final Widget child;
  final Widget? back;
  final double maxVerticalTilt;
  final double horizontalSensitivity;
  final double verticalSensitivity;

  const Interactive3DCard({
    super.key,
    required this.child,
    this.back,
    this.maxVerticalTilt = 0.30,
    this.horizontalSensitivity = 0.010,
    this.verticalSensitivity = 0.012,
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

  bool get _isDragging => _dragActive;
  bool _dragActive = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addListener(_onAnimationTick);
  }

  @override
  void dispose() {
    _controller.removeListener(_onAnimationTick);
    _controller.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    final t = Curves.easeOutCubic.transform(_controller.value);
    setState(() {
      _rotationX = _lerp(_fromX, _toX, t);
      _rotationY = _lerp(_fromY, _toY, t);
    });
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _clampTilt(double value) {
    return value.clamp(-widget.maxVerticalTilt, widget.maxVerticalTilt);
  }

  void _animateTo({required double toX, required double toY}) {
    _fromX = _rotationX;
    _fromY = _rotationY;
    _toX = toX;
    _toY = toY;
    _controller
      ..stop()
      ..value = 0
      ..forward();
  }

  void _handlePanStart(DragStartDetails details) {
    _controller.stop();
    _dragActive = true;
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
    _animateTo(toX: 0, toY: 0);
  }

  void _handleTap() {
    if (_isDragging) return;
    _controller.stop();
    final peekY = _rotationY == 0 ? 0.18 : _rotationY * 1.3;
    _animateTo(toX: 0, toY: peekY);
    _controller.addStatusListener(_tapPeekListener);
  }

  void _tapPeekListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _controller.removeStatusListener(_tapPeekListener);
      _animateTo(toX: 0, toY: 0);
    }
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onTap: _handleTap,
      child: Transform(
        alignment: Alignment.center,
        transform: matrix,
        child: showBack ? widget.back : widget.child,
      ),
    );
  }
}