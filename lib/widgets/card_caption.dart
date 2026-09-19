import 'package:flutter/material.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';

/// Two-line caption under a card thumbnail: the card name, then
/// "Set name · #number".
///
/// When space runs out the set name is what gets ellipsized, so the card
/// number always stays visible.
class CardCaption extends StatelessWidget {
  final PokemonCardData card;

  const CardCaption({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          card.name,
          textAlign: TextAlign.center,
          style: PokeBinderText.cardName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: PokeBinderSpacing.sp0),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                card.setName,
                style: PokeBinderText.cardMeta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              ' · #${card.cardNumber}',
              style: PokeBinderText.cardMeta,
              maxLines: 1,
              softWrap: false,
            ),
          ],
        ),
      ],
    );
  }
}
