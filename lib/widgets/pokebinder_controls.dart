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
        child: Text(label, style: PokeBinderText.backLink),
      ),
    );
  }
}

class CollectionSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool enabled;
  final Widget? trailing;

  const CollectionSearchBar({
    super.key,
    required this.hint,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final field = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: PokeBinderSpacing.sp2,
      ),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            size: 16,
            color: PokeBinderColors.inkSoft,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: IgnorePointer(
              ignoring: !enabled,
              child: TextField(
                enabled: enabled,
                onChanged: onChanged,
                style: const TextStyle(fontSize: 11.5, color: PokeBinderColors.ink),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: const TextStyle(color: Color(0xFFA89C86)),
                ),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return field;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: field,
      ),
    );
  }
}

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool ghost;
  final bool enabled;
  final IconData? icon;

  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.ghost = false,
    this.enabled = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle =
        ghost ? PokeBinderText.buttonGhostLabel : PokeBinderText.buttonLabel;

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
              gradient: ghost ? null : PokeBinderColors.redGradient,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: labelStyle.color),
                  const SizedBox(width: 6),
                ],
                Text(label, style: labelStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}