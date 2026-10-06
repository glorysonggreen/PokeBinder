import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/pokebinder_motion.dart';
import '../theme/pokebinder_theme.dart';
import '../services/audio_service.dart';

class FadeSlideIn extends StatelessWidget {
  final Widget child;

  final int index;

  final double offset;

  final double startScale;

  final bool overshoot;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 14,
    this.startScale = 0.96,
    this.overshoot = true,
  });

  const FadeSlideIn.fade({super.key, required this.child})
      : index = 0,
        offset = 0,
        startScale = 1,
        overshoot = false;

  @override
  Widget build(BuildContext context) {
    final enter = PokeBinderMotion.adapt(context, PokeBinderMotion.enter);
    if (enter == Duration.zero) return child;

    final steps =
        index > PokeBinderMotion.maxStaggered ? PokeBinderMotion.maxStaggered : index;
    final delay = PokeBinderMotion.stagger * steps;
    final total = enter + delay;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: overshoot ? PokeBinderMotion.bounce : PokeBinderMotion.smooth,
      ),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0).toDouble(),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * offset),
          child: Transform.scale(
            scale: startScale + (1 - startScale) * t,
            child: child,
          ),
        ),
      ),
    );
  }
}

class PopIn extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const PopIn({super.key, required this.child, this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    final pop = PokeBinderMotion.adapt(context, PokeBinderMotion.pop * 1.5);
    if (pop == Duration.zero) return child;

    final total = pop + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: PokeBinderMotion.spring,
      ),
      child: child,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
    );
  }
}

class BouncySwitcher extends StatelessWidget {
  final Widget child;

  const BouncySwitcher({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: PokeBinderMotion.adapt(context, PokeBinderMotion.pop),
      reverseDuration: PokeBinderMotion.adapt(context, PokeBinderMotion.fast),
      switchInCurve: PokeBinderMotion.spring,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: child,
    );
  }
}

class CountUpText extends StatelessWidget {
  final String value;
  final TextStyle? style;

  const CountUpText(this.value, {super.key, this.style});

  static final _number = RegExp(r'\d[\d,]*(\.\d+)?');

  @override
  Widget build(BuildContext context) {
    final match = _number.firstMatch(value);
    final duration = PokeBinderMotion.adapt(context, PokeBinderMotion.count);
    if (match == null || duration == Duration.zero) {
      return Text(value, style: style);
    }

    final digits = match.group(0)!;
    final target = double.parse(digits.replaceAll(',', ''));
    final decimals =
        digits.contains('.') ? digits.length - digits.indexOf('.') - 1 : 0;
    final useCommas = digits.contains(',');
    final prefix = value.substring(0, match.start);
    final suffix = value.substring(match.end);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: duration,
      curve: PokeBinderMotion.smooth,
      builder: (context, current, _) {
        var text = current.toStringAsFixed(decimals);
        if (useCommas) text = _withCommas(text);
        return Text('$prefix$text$suffix', style: style);
      },
    );
  }

  static String _withCommas(String number) {
    final parts = number.split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return parts.length > 1 ? '$whole.${parts[1]}' : whole;
  }
}

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final HitTestBehavior behavior;
  final double? shineRadius;

  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.behavior = HitTestBehavior.deferToChild,
    this.shineRadius,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  void _down() {
    PokeBinderAudio.play(
      widget.shineRadius != null ? Sfx.cardSelect : Sfx.tap,
    );
    setState(() => _pressed = true);
    if (widget.shineRadius != null &&
        !MediaQuery.disableAnimationsOf(context)) {
      _shine.forward(from: 0);
    }
  }

  void _up() {
    if (_pressed) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.shineRadius;
    final content = radius == null
        ? widget.child
        : Stack(
            fit: StackFit.passthrough,
            children: [
              widget.child,
              Positioned.fill(
                child: IgnorePointer(
                  child: _FoilShine(animation: _shine, radius: radius),
                ),
              ),
            ],
          );

    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onTapDown: (_) => _down(),
      onTapUp: (_) => _up(),
      onTapCancel: _up,
      child: AnimatedScale(
        scale: _pressed ? PokeBinderMotion.pressedScale : 1,
        duration: PokeBinderMotion.adapt(
          context,
          _pressed ? PokeBinderMotion.press : PokeBinderMotion.release,
        ),
        curve: _pressed ? PokeBinderMotion.curve : PokeBinderMotion.spring,
        child: content,
      ),
    );
  }
}

class _FoilShine extends StatelessWidget {
  final Animation<double> animation;
  final double radius;

  const _FoilShine({required this.animation, required this.radius});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        if (animation.isDismissed || animation.isCompleted) {
          return const SizedBox.shrink();
        }
        final slide = Curves.easeInOut.transform(animation.value) * 2 - 1;
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-1, -0.6),
                end: const Alignment(1, 0.6),
                colors: const [
                  Color(0x00FFFFFF),
                  Color(0x66FFF1C2),
                  Color(0x00FFFFFF),
                ],
                stops: const [0.3, 0.5, 0.7],
                transform: _SlideGradient(slide),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double slide;
  const _SlideGradient(this.slide);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * slide, 0, 0);
}

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );

  late final Animation<double> _t =
      CurvedAnimation(parent: _controller, curve: PokeBinderMotion.smooth);

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index &&
        !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: IndexedStack(index: widget.index, children: widget.children),
      builder: (context, child) => Opacity(
        opacity: 0.3 + 0.7 * _t.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _t.value) * 10),
          child: child,
        ),
      ),
    );
  }
}

class CardDealIn extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const CardDealIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final deal = PokeBinderMotion.adapt(context, PokeBinderMotion.deal);
    if (deal == Duration.zero) return child;

    final total = deal + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: PokeBinderMotion.emphasized,
      ),
      child: child,
      builder: (context, t, child) {
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY((1 - t) * -0.85)
          ..rotateX((1 - t) * 0.12);
        return Opacity(
          opacity: (t * 2.2).clamp(0.0, 1.0).toDouble(),
          child: Transform(
            alignment: Alignment.center,
            transform: matrix,
            child: Transform.scale(
              scale: 0.86 + 0.14 * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class AnimatedFormError extends StatefulWidget {
  final String message;
  final int pulse;

  const AnimatedFormError({super.key, required this.message, this.pulse = 0});

  @override
  State<AnimatedFormError> createState() => _AnimatedFormErrorState();
}

class _AnimatedFormErrorState extends State<AnimatedFormError>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    PokeBinderAudio.play(Sfx.error);
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedFormError oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.message != widget.message ||
            oldWidget.pulse != widget.pulse) &&
        !MediaQuery.disableAnimationsOf(context)) {
      PokeBinderAudio.play(Sfx.error);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final dx = math.sin(t * math.pi * 6) * (1 - t) * 7;
        return Opacity(
          opacity: (t * 4).clamp(0.0, 1.0).toDouble(),
          child: Transform.translate(offset: Offset(dx, 0), child: child),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              size: 14,
              color: PokeBinderColors.danger,
            ),
          ),
          const SizedBox(width: PokeBinderSpacing.sp1 + 2),
          Expanded(
            child: Text(widget.message, style: PokeBinderText.formError),
          ),
        ],
      ),
    );
  }
}
