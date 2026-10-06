import 'package:flutter/material.dart';

import '../theme/pokebinder_theme.dart';
import 'motion_widgets.dart';
import 'pokeball.dart';

class AuthBanner extends StatelessWidget {
  final String heading;
  final String subtitle;
  final Widget? footer;

  const AuthBanner({
    super.key,
    required this.heading,
    required this.subtitle,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: PokeBinderSpacing.sp5,
        vertical: PokeBinderSpacing.sp6,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PokeBinderColors.white, Color(0xFFF7EFE0)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: kCardElevation,
      ),
      child: Column(
        children: [
          const PopIn(child: PokeballBadge(size: 64)),
          const SizedBox(height: PokeBinderSpacing.sp4),
          FadeSlideIn(
            index: 1,
            child: Text(
              heading,
              textAlign: TextAlign.center,
              style: PokeBinderText.heading,
            ),
          ),
          const SizedBox(height: PokeBinderSpacing.sp1),
          FadeSlideIn(
            index: 2,
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: PokeBinderText.subtitle,
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: PokeBinderSpacing.sp3),
            FadeSlideIn(index: 3, child: footer!),
          ],
        ],
      ),
    );
  }
}
