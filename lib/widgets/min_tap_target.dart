import 'package:flutter/material.dart';
import '../theme/pokebinder_theme.dart';

class MinTapTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final String? semanticLabel;

  final AlignmentGeometry alignment;

  const MinTapTarget({
    super.key,
    required this.child,
    required this.onTap,
    this.size = kMinTapTarget,
    this.semanticLabel,
    this.alignment = Alignment.center,
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
          child: Align(alignment: alignment, child: child),
        ),
      ),
    );
  }
}
