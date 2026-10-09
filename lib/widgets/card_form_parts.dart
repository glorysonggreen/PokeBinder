import 'package:flutter/material.dart';
import '../config/field_limits.dart';
import '../config/pricing.dart';
import '../theme/pokebinder_theme.dart';
import 'pokebinder_controls.dart';
import 'pokebinder_form_fields.dart';

const double kPairedFieldHeight = 52;

class FormSectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const FormSectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: PokeBinderSpacing.sp2,
        bottom: PokeBinderSpacing.sp3,
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: PokeBinderColors.redDeep),
          const SizedBox(width: PokeBinderSpacing.sp2),
          Text(label.toUpperCase(), style: PokeBinderText.eyebrow),
          const SizedBox(width: PokeBinderSpacing.sp2),
          Expanded(
            child: Container(
              height: 1,
              color: PokeBinderColors.ink.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  static const _min = 1;
  static const _max = 999;

  const QuantityStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final canDecrease = value > _min;
    final canIncrease = value < _max;

    return Container(
      height: kPairedFieldHeight,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            label: 'Decrease quantity',
            enabled: canDecrease,
            onTap: () => onChanged(value - 1),
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: PokeBinderText.selectValue,
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            label: 'Increase quantity',
            enabled: canIncrease,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: enabled,
      child: Material(
        color: enabled
            ? PokeBinderColors.red.withValues(alpha: 0.1)
            : PokeBinderColors.ink.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: kPairedFieldHeight - 10,
            height: kPairedFieldHeight - 10,
            child: Icon(
              icon,
              size: 20,
              color: enabled ? PokeBinderColors.redDeep : PokeBinderColors.hint,
            ),
          ),
        ),
      ),
    );
  }
}

class MiniAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  final bool quiet;

  const MiniAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.quiet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: quiet
          ? Colors.transparent
          : PokeBinderColors.red.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: quiet
            ? BorderSide(color: PokeBinderColors.ink.withValues(alpha: 0.16))
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PokeBinderSpacing.sp3,
            vertical: PokeBinderSpacing.sp2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: PokeBinderColors.redDeep),
              const SizedBox(width: PokeBinderSpacing.sp1),
              Text(label, style: PokeBinderText.tagLabel(PokeBinderColors.redDeep)),
            ],
          ),
        ),
      ),
    );
  }
}

class FinishChip extends StatelessWidget {
  final String label;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  const FinishChip({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $price',
      child: Material(
        color: selected
            ? PokeBinderColors.red.withValues(alpha: 0.1)
            : PokeBinderColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected
                ? PokeBinderColors.red.withValues(alpha: 0.55)
                : PokeBinderColors.ink.withValues(alpha: 0.1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PokeBinderSpacing.sp3,
              vertical: PokeBinderSpacing.sp3,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check_rounded,
                      size: 15, color: PokeBinderColors.red),
                  const SizedBox(width: PokeBinderSpacing.sp1),
                ],
                Text(label, style: PokeBinderText.pillLabel(selected: selected)),
                const SizedBox(width: PokeBinderSpacing.sp2),
                Text(price, style: PokeBinderText.listRowSubtitle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FormActionBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onSubmit;

  const FormActionBar({
    super.key,
    required this.label,
    required this.icon,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PokeBinderColors.cream,
        border: Border(
          top: BorderSide(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        ),
        boxShadow: [
          BoxShadow(
            color: PokeBinderColors.ink.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(PokeBinderSpacing.sp3).copyWith(
            left: PokeBinderSpacing.sp4,
            right: PokeBinderSpacing.sp4,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PillButton(
                  label: 'Cancel',
                  ghost: true,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp2),
              Expanded(
                flex: 3,
                child: PillButton(label: label, icon: icon, onTap: onSubmit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EstimatedValueField extends StatelessWidget {
  final TextEditingController controller;
  final double? suggested;
  final bool edited;
  final ValueChanged<String> onChanged;
  final VoidCallback onUseSuggested;

  const EstimatedValueField({
    super.key,
    required this.controller,
    required this.suggested,
    required this.edited,
    required this.onChanged,
    required this.onUseSuggested,
  });

  @override
  Widget build(BuildContext context) {
    final suggestion = suggested;
    final differs = suggestion != null &&
        controller.text.trim() != suggestion.toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledFormField(
          label: 'Estimated value',
          child: TextField(
            controller: controller,
            inputFormatters: const [PesoAmountFormatter()],
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: PokeBinderText.input,
            onChanged: onChanged,
            decoration: pokeInputDecoration(
              hint: '0',
              icon: Icons.payments_outlined,
            ).copyWith(
              prefixText: '₱ ',
              prefixStyle: PokeBinderText.selectValue,
            ),
          ),
        ),
        if (suggestion != null)
          Padding(
            padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    edited
                        ? 'Using your own value.'
                        : 'Adjusts with the condition. Type your own value '
                            'to override it.',
                    style: PokeBinderText.listRowSubtitle,
                  ),
                ),
                if (differs) ...[
                  const SizedBox(width: PokeBinderSpacing.sp2),
                  MiniAction(
                    label: 'Use ${formatPeso(suggestion)}',
                    icon: Icons.refresh_rounded,
                    onTap: onUseSuggested,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
