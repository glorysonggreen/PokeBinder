import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/pokebinder_theme.dart';

InputDecoration pokeInputDecoration({
  String? hint,
  IconData? icon,
  Widget? suffixIcon,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFA89C86), fontSize: 11.5),
    filled: true,
    fillColor: PokeBinderColors.white,
    isDense: true,
    prefixIcon: icon != null
        ? Icon(icon, size: 16, color: PokeBinderColors.redDeep.withValues(alpha: 0.55))
        : null,
    prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 0),
    suffixIcon: suffixIcon,
    suffixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 0),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: PokeBinderColors.red.withValues(alpha: 0.55),
        width: 1.5,
      ),
    ),
  );
}

class LabeledFormField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabeledFormField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label.toUpperCase(), style: PokeBinderText.formLabel),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: PokeBinderColors.ink.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class FormFieldRow extends StatelessWidget {
  final Widget left;
  final Widget right;

  const FormFieldRow({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }
}

class PokeDropdownOption<T> {
  final T value;
  final String label;
  final IconData? icon;
  
  const PokeDropdownOption(this.value, this.label, {this.icon});
}

class PokeDropdownField<T> extends StatelessWidget {
  final T value;
  final List<PokeDropdownOption<T>> options;
  final ValueChanged<T> onChanged;
  final IconData? icon;

  const PokeDropdownField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final selected =
        options.firstWhere((o) => o.value == value, orElse: () => options.first);
    final displayIcon = selected.icon ?? icon;

    return LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth = constraints.maxWidth.isFinite
            ? math.max(constraints.maxWidth, 170.0)
            : 190.0;

        return Theme(
          data: Theme.of(context).copyWith(
            highlightColor: PokeBinderColors.red.withValues(alpha: 0.06),
            splashColor: PokeBinderColors.red.withValues(alpha: 0.06),
            hoverColor: PokeBinderColors.red.withValues(alpha: 0.05),
          ),
          child: PopupMenuButton<T>(
            initialValue: value,
            onSelected: onChanged,
            offset: const Offset(0, 50),
            color: PokeBinderColors.white,
            elevation: 8,
            shadowColor: PokeBinderColors.ink.withValues(alpha: 0.2),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
            ),
            constraints: BoxConstraints(minWidth: menuWidth),
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemBuilder: (context) => [
              for (final option in options)
                PopupMenuItem<T>(
                  value: option.value,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _PokeDropdownMenuRow(
                    label: option.label,
                    icon: option.icon,
                    selected: option.value == value,
                  ),
                ),
            ],
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                color: PokeBinderColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (displayIcon != null) ...[
                    Icon(displayIcon,
                        size: 16,
                        color: PokeBinderColors.redDeep.withValues(alpha: 0.55)),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      selected.label,
                      overflow: TextOverflow.ellipsis,
                      style: PokeBinderText.fieldValue
                          .copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: PokeBinderColors.inkSoft,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PokeDropdownMenuRow extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;

  const _PokeDropdownMenuRow({
    required this.label,
    this.icon,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PokeBinderSpacing.sp2,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: selected ? PokeBinderColors.red.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 15,
                color: selected
                    ? PokeBinderColors.redDeep
                    : PokeBinderColors.inkSoft),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: PokeBinderText.chakraPetch(TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? PokeBinderColors.redDeep : PokeBinderColors.ink,
              )),
            ),
          ),
          if (selected)
            const Padding(
              padding: EdgeInsets.only(left: PokeBinderSpacing.sp1),
              child: Icon(
                Icons.check_rounded,
                size: 15,
                color: PokeBinderColors.red,
              ),
            ),
        ],
      ),
    );
  }
}