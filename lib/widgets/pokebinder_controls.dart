import 'package:flutter/gestures.dart';
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

class SegmentedTabBar extends StatelessWidget {
  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const SegmentedTabBar({
    super.key,
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: PokeBinderColors.cream2,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onChanged(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == index ? PokeBinderColors.white : null,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: i == index
                          ? [
                              BoxShadow(
                                color:
                                    PokeBinderColors.ink.withValues(alpha: 0.12),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      labels[i],
                      style: i == index
                          ? PokeBinderText.tabLabelActive
                          : PokeBinderText.tabLabelInactive,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AuthLinkText extends StatefulWidget {
  final String prefix;
  final String linkLabel;
  final VoidCallback onTap;
  final TextAlign textAlign;

  const AuthLinkText({
    super.key,
    this.prefix = '',
    required this.linkLabel,
    required this.onTap,
    this.textAlign = TextAlign.center,
  });

  @override
  State<AuthLinkText> createState() => _AuthLinkTextState();
}

class _AuthLinkTextState extends State<AuthLinkText> {
  late final _recognizer = TapGestureRecognizer()..onTap = widget.onTap;

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: widget.textAlign,
      text: TextSpan(
        style: PokeBinderText.subtitle,
        children: [
          if (widget.prefix.isNotEmpty) TextSpan(text: widget.prefix),
          TextSpan(
            text: widget.linkLabel,
            style: PokeBinderText.backLink,
            recognizer: _recognizer,
          ),
        ],
      ),
    );
  }
}

class PasswordVisibilityToggle extends StatelessWidget {
  final bool obscured;
  final VoidCallback onTap;

  const PasswordVisibilityToggle({
    super.key,
    required this.obscured,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 16,
            color: PokeBinderColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

class ChoiceChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ChoiceChipPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? null : PokeBinderColors.white,
            gradient: selected ? PokeBinderColors.redGradient : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : PokeBinderColors.ink.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            label,
            style: selected
                ? PokeBinderText.chipLabelActive
                : PokeBinderText.chipLabel,
          ),
        ),
      ),
    );
  }
}

class EmptyFilterState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onClearFilters;
  final String clearFiltersLabel;

  const EmptyFilterState({
    super.key,
    this.icon = Icons.filter_alt_off_rounded,
    required this.title,
    required this.subtitle,
    this.onClearFilters,
    this.clearFiltersLabel = 'Clear filters',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: PokeBinderSpacing.sp6,
        horizontal: PokeBinderSpacing.sp4,
      ),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PokeBinderColors.cream2.withValues(alpha: 0.6),
            ),
            child: Icon(
              icon,
              size: 24,
              color: PokeBinderColors.goldDeep.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: PokeBinderSpacing.sp3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: PokeBinderText.subtitle.copyWith(
              fontWeight: FontWeight.w600,
              color: PokeBinderColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: PokeBinderText.subtitle,
          ),
          if (onClearFilters != null) ...[
            const SizedBox(height: PokeBinderSpacing.sp3),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onClearFilters,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PokeBinderSpacing.sp3,
                    vertical: PokeBinderSpacing.sp1,
                  ),
                  child: Text(clearFiltersLabel, style: PokeBinderText.backLink),
                ),
              ),
            ),
          ],
        ],
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
                Flexible(
                  child: Text(
                    label,
                    style: labelStyle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}