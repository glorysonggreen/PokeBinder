import 'package:flutter/material.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';

class RarityTag extends StatelessWidget {
  final String rarity;

  const RarityTag({super.key, required this.rarity});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(rarityIconFor(rarity), size: 11, color: PokeBinderColors.goldDeep),
        const SizedBox(width: PokeBinderSpacing.sp1),
        Text(rarity, style: PokeBinderText.listRowSubtitle),
      ],
    );
  }
}

class ConditionTag extends StatelessWidget {
  final String code;

  const ConditionTag({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final label = kConditionOptions
        .firstWhere((c) => c.$2 == code, orElse: () => (code, code))
        .$1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(conditionIconFor(code), size: 11, color: PokeBinderColors.teal),
        const SizedBox(width: PokeBinderSpacing.sp1),
        Text(label, style: PokeBinderText.listRowSubtitle),
      ],
    );
  }
}
