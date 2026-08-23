import 'package:flutter/material.dart';
import '../theme/pokebinder_theme.dart';

InputDecoration pokeInputDecoration({String? hint}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: PokeBinderColors.ink.withValues(alpha: 0.14)),
  );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFA89C86), fontSize: 11.5),
    filled: true,
    fillColor: PokeBinderColors.white,
    isDense: true,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: PokeBinderColors.red.withValues(alpha: 0.4),
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
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(label.toUpperCase(), style: PokeBinderText.formLabel),
          ),
          child,
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