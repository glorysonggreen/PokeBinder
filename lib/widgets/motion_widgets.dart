import 'package:flutter/material.dart';
import '../theme/pokebinder_motion.dart';

// ---------------------------------------------------------------------------
// FadeSlideIn: "deal" content onto the page
// ---------------------------------------------------------------------------

/// Fades its [child] in while it lifts up and grows from 96% to full size,
/// with a tiny overshoot at the end so it feels like it lands.
///
/// Give each item in a list or grid its position as [index] and they arrive
/// one after another (a "staggered" entrance). The delay is capped, see
/// [PokeBinderMotion.maxStaggered].
///
///   for (var i = 0; i < cards.length; i++)
///     FadeSlideIn(index: i, child: CardTile(cards[i]))
///
/// To replay the animation when something changes (for example when the user
/// switches tabs), give it a `key` that changes:
///
///   FadeSlideIn.fade(key: ValueKey(_tabIndex), child: ...)
class FadeSlideIn extends StatelessWidget {
  final Widget child;

  /// Position in a list. 0 = no delay, 1 = one step later, and so on.
  final int index;

  /// How many pixels the child travels upward while arriving.
  final double offset;

  /// Size the child starts at (1 = no scaling).
  final double startScale;

  /// Whether the arrival overshoots slightly before settling.
  final bool overshoot;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 14,
    this.startScale = 0.96,
    this.overshoot = true,
  });

  /// A plain fade with no movement. Use it on a whole tab or screen whose
  /// items already animate on their own, so the two do not fight.
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

    // One TweenAnimationBuilder runs 0 -> 1 when the widget first appears.
    // The Interval makes it wait for [delay] before it starts moving, so we
    // need no Timer and no AnimationController.
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
        // t can briefly pass 1.0 because of the overshoot; opacity cannot.
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

// ---------------------------------------------------------------------------
// PopIn: badges and icons that bounce into existence
// ---------------------------------------------------------------------------

/// Grows its [child] from nothing with a springy wobble. Great for badges,
/// logos and icons.
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

// ---------------------------------------------------------------------------
// BouncySwitcher: swap one icon for another with a pop
// ---------------------------------------------------------------------------

/// Cross-swaps its [child] whenever the child's `key` changes. The new child
/// pops in with a springy bounce and the old one shrinks away quickly.
///
///   BouncySwitcher(
///     child: Icon(pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
///                 key: ValueKey(pinned)),
///   )
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

// ---------------------------------------------------------------------------
// CountUpText: numbers that tick up
// ---------------------------------------------------------------------------

/// Shows [value] but counts its first number up from 0 the first time it
/// appears, and counts from the old number to the new one when it changes.
/// Text around the number is kept as-is, so it works for "128",
/// "₱1.2k" and "1,024".
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

// ---------------------------------------------------------------------------
// PressableScale: squish on press, spring back on release (+ optional foil)
// ---------------------------------------------------------------------------

/// A tap target that squishes while the finger is down and springs back with
/// a little wobble when it lifts.
///
/// It is a drop-in replacement for a plain `GestureDetector(onTap: ...)`, so
/// swapping it in does not change what a tap does. Because it listens to the
/// tap gesture (not raw pointer events), the tile springs back on its own if
/// the user starts scrolling instead of tapping.
///
/// Set [shineRadius] (the corner radius of your child) to also sweep a
/// glossy "holo foil" highlight across it on every press. That is the trading
/// card touch, so use it on card artwork.
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
        // Quick on the way down, slow and springy on the way back up.
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

/// The glossy band that sweeps across a card. Purely decorative.
class _FoilShine extends StatelessWidget {
  final Animation<double> animation;
  final double radius;

  const _FoilShine({required this.animation, required this.radius});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        // Nothing to draw until the first press, or once the sweep is done.
        if (animation.isDismissed || animation.isCompleted) {
          return const SizedBox.shrink();
        }
        // Slide the highlight from just off the left edge to just off the
        // right edge (-1 to +1 of the card's width).
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
                  Color(0x66FFF1C2), // warm gold-white, like foil
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

// ---------------------------------------------------------------------------
// FadeIndexedStack: bottom-navigation tabs
// ---------------------------------------------------------------------------

/// Works like [IndexedStack] (only one child is visible, and the hidden ones
/// keep their state), but the newly shown child fades in and settles up from
/// a few pixels below whenever [index] changes.
///
/// Used for the bottom-navigation tabs in [AppShell].
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
    value: 1, // start fully visible so the first screen does not animate
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
        // Fade from 30% rather than 0%, so a switch never flashes empty.
        opacity: 0.3 + 0.7 * _t.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _t.value) * 10),
          child: child,
        ),
      ),
    );
  }
}
