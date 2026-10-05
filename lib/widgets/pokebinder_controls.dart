import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/pokebinder_motion.dart';
import '../theme/pokebinder_theme.dart';
import 'motion_widgets.dart';
import 'pokeball.dart';
import '../services/audio_service.dart';

class BackLink extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const BackLink({super.key, required this.onTap, this.label = '‹ Back'});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: PokeBinderSpacing.sp1),
        child: Text(label, style: PokeBinderText.backLink),
      ),
    );
  }
}

class CollectionSearchBar extends StatefulWidget {
  final String hint;

  final TextEditingController? controller;

  final String? text;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool enabled;

  const CollectionSearchBar({
    super.key,
    required this.hint,
    this.controller,
    this.text,
    this.onChanged,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<CollectionSearchBar> createState() => _CollectionSearchBarState();
}

class _CollectionSearchBarState extends State<CollectionSearchBar> {
  TextEditingController? _ownController;

  TextEditingController get _controller =>
      widget.controller ??
      (_ownController ??= TextEditingController(text: widget.text));

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(CollectionSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_onTextChanged);
      _controller.addListener(_onTextChanged);
    }
    final text = widget.text;
    if (text != null && text != _controller.text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _ownController?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final showClear = widget.enabled && _controller.text.isNotEmpty;

    final field = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PokeBinderSpacing.sp3,
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
          const SizedBox(width: PokeBinderSpacing.sp2),
          Expanded(
            child: IgnorePointer(
              ignoring: !widget.enabled,
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                onChanged: widget.onChanged,
                style: PokeBinderText.input,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: widget.hint,
                  hintStyle: PokeBinderText.hint,
                ),
              ),
            ),
          ),
          if (showClear) ...[
            const SizedBox(width: PokeBinderSpacing.sp2),
            Tooltip(
              message: 'Clear search',
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _clear,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.backspace_outlined,
                    size: 18,
                    color: PokeBinderColors.inkSoft,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.onTap == null) return field;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
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
    final count = labels.length;
    // Maps the selected index onto Alignment's -1..1 range.
    final thumbX = count <= 1 ? 0.0 : -1 + 2 * index / (count - 1);

    return Container(
      padding: const EdgeInsets.all(PokeBinderSpacing.sp1),
      decoration: BoxDecoration(
        color: PokeBinderColors.cream2,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Stack(
        children: [
          // The white "thumb" glides to the selected segment.
          if (count > 0)
            Positioned.fill(
              child: AnimatedAlign(
                alignment: Alignment(thumbX, 0),
                duration: PokeBinderMotion.adapt(context, PokeBinderMotion.pop),
                curve: PokeBinderMotion.bounce,
                child: FractionallySizedBox(
                  widthFactor: 1 / count,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: PokeBinderColors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: PokeBinderColors.ink.withValues(alpha: 0.12),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              for (var i = 0; i < count; i++)
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onChanged(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: PokeBinderSpacing.sp2,
                        ),
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: PokeBinderMotion.fast,
                          style: i == index
                              ? PokeBinderText.tabLabelActive
                              : PokeBinderText.tabLabelInactive,
                          child: Text(labels[i]),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
  late final _recognizer = TapGestureRecognizer()
    ..onTap = () {
      PokeBinderAudio.play(Sfx.tap);
      widget.onTap();
    };

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
          padding: const EdgeInsets.all(PokeBinderSpacing.sp2),
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
    return FadeSlideIn(
      child: Container(
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
            PopIn(
              delay: const Duration(milliseconds: 120),
              child: Container(
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
            const SizedBox(height: PokeBinderSpacing.sp1),
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
      ),
    );
  }
}

class PillButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool ghost;
  final bool enabled;
  final IconData? icon;

  /// Shows a spinning Poké Ball in place of [icon]. Pair with `enabled: false`
  /// while the request is in flight.
  final bool loading;

  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.ghost = false,
    this.enabled = true,
    this.icon,
    this.loading = false,
  });

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    final ghost = widget.ghost;
    final icon = widget.icon;
    final labelStyle =
        ghost ? PokeBinderText.buttonGhostLabel : PokeBinderText.buttonLabel;

    return Opacity(
      opacity: widget.enabled ? 1 : 0.45,
      child: AnimatedScale(
        scale: _pressed ? PokeBinderMotion.pressedScale : 1,
        duration: PokeBinderMotion.adapt(
          context,
          _pressed ? PokeBinderMotion.press : PokeBinderMotion.release,
        ),
        curve: _pressed ? PokeBinderMotion.curve : PokeBinderMotion.spring,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.enabled ? widget.onTap : null,
            onHighlightChanged: (value) {
              if (mounted) setState(() => _pressed = value);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: PokeBinderSpacing.sp3,
              ),
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
                  if (widget.loading) ...[
                    PokeballSpinner(
                      size: 16,
                      color: labelStyle.color ?? PokeBinderColors.white,
                    ),
                    const SizedBox(width: PokeBinderSpacing.sp2),
                  ] else if (icon != null) ...[
                    Icon(icon, size: 14, color: labelStyle.color),
                    const SizedBox(width: PokeBinderSpacing.sp1),
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
      ),
    );
  }
}

class DangerActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const DangerActionButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PokeBinderSpacing.sp3,
              vertical: PokeBinderSpacing.sp2,
            ),
            decoration: BoxDecoration(
              color: PokeBinderColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.delete_outline,
                  size: 14,
                  color: PokeBinderColors.danger,
                ),
                const SizedBox(width: PokeBinderSpacing.sp2),
                Text(label, style: PokeBinderText.buttonDangerLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton.icon(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          icon: const Icon(
            Icons.delete_outline,
            size: 16,
            color: PokeBinderColors.danger,
          ),
          label: Text(
            confirmLabel,
            style: const TextStyle(color: PokeBinderColors.danger),
          ),
        ),
      ],
    ),
  );
  if (confirmed == true) PokeBinderAudio.play(Sfx.remove);
  return confirmed ?? false;
}
