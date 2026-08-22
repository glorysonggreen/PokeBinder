import 'package:flutter/material.dart';
import '../theme/pokebinder_theme.dart';

class BackLink extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const BackLink({super.key, required this.onTap, this.label = '‹ Back'});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: PokeBinderColors.redDeep,
          ),
        ),
      ),
    );
  }
}

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool ghost;
  final bool enabled;

  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.ghost = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: ghost ? PokeBinderColors.white : null,
              gradient: ghost
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFE0402A), PokeBinderColors.red],
                    ),
              border: ghost
                  ? Border.all(
                      color: PokeBinderColors.red.withValues(alpha: 0.35),
                      width: 1.5,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: ghost
                      ? PokeBinderColors.ink.withValues(alpha: 0.1)
                      : PokeBinderColors.redDeep,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              label,
              style: ghost
                  ? PokeBinderText.buttonGhostLabel
                  : PokeBinderText.buttonLabel,
            ),
          ),
        ),
      ),
    );
  }
}