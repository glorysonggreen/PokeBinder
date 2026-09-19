import 'package:flutter/material.dart';
import '../theme/pokebinder_theme.dart';

/// Wraps a small visual control (a pill, an icon, a text link) so it keeps
/// its compact look but always sits inside a tap area of at least
/// [kMinTapTarget] (44) in both dimensions, per Apple's 44pt / Material's
/// 48dp touch-target guidance.
///
/// The extra space is invisible — [child] is centered inside the enlarged
/// box — so this only changes how much of the surrounding layout responds
/// to a tap, not how big the control looks.
///
/// Use this instead of a bare `GestureDetector` whenever the visual control
/// is smaller than [kMinTapTarget] and there's no other reason (e.g. a
/// fixed-height row already sized to 44+) that its tap area is already
/// large enough.
class MinTapTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final String? semanticLabel;

  const MinTapTarget({
    super.key,
    required this.child,
    required this.onTap,
    this.size = kMinTapTarget,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: size, minHeight: size),
          child: Center(child: child),
        ),
      ),
    );
  }
}
