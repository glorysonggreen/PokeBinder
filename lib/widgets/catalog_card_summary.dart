import 'package:flutter/material.dart';
import '../config/pricing.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import 'card_viewer.dart';
import 'pokemon_card_widget.dart';

String shortDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const InfoChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: PokeBinderSpacing.chip,
      decoration: BoxDecoration(
        color: highlight
            ? PokeBinderColors.gold.withValues(alpha: 0.2)
            : PokeBinderColors.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: highlight
                ? PokeBinderColors.goldDeep
                : PokeBinderColors.inkSoft,
          ),
          const SizedBox(width: PokeBinderSpacing.sp1),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: PokeBinderText.tagLabel(
                highlight ? PokeBinderColors.ink : PokeBinderColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CatalogSummary extends StatelessWidget {
  final String name;
  final String setName;
  final String number;
  final String rarity;
  final PokemonCardType? type;
  final CardSupertype? supertype;
  final String? subtype;
  final String? imagePath;
  final bool showPrice;
  final double? priceUsd;
  final double? pricePhp;
  final DateTime? priceUpdatedAt;

  final String? priceCaption;

  final String? finishChip;

  const CatalogSummary({
    required this.name,
    required this.setName,
    required this.number,
    required this.rarity,
    required this.type,
    required this.supertype,
    required this.subtype,
    required this.imagePath,
    required this.showPrice,
    required this.priceUsd,
    required this.pricePhp,
    required this.priceUpdatedAt,
    this.priceCaption,
    this.finishChip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: PokeBinderSpacing.sp5),
      padding: const EdgeInsets.all(PokeBinderSpacing.sp4),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.09)),
        boxShadow: kCardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                button: true,
                label: 'View $name full size',
                child: GestureDetector(
                  onTap: imagePath == null
                      ? null
                      : () => showCardViewer(context, imagePath: imagePath!),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: PokeBinderColors.ink.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CardThumbnail(
                      card: null,
                      imageAssetPath: imagePath,
                      width: 128,
                      height: 179,
                      borderRadius: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PokeBinderText.headingSm,
                    ),
                    if (setName.isNotEmpty) ...[
                      const SizedBox(height: PokeBinderSpacing.sp1),
                      Text(setName, style: PokeBinderText.subtitle),
                    ],
                    if (number.isNotEmpty) ...[
                      const SizedBox(height: PokeBinderSpacing.sp0),
                      Text('Card #$number', style: PokeBinderText.listRowSubtitle),
                    ],
                    const SizedBox(height: PokeBinderSpacing.sp3),
                    Wrap(
                      spacing: PokeBinderSpacing.sp2,
                      runSpacing: PokeBinderSpacing.sp2,
                      children: [
                        InfoChip(
                          icon: rarityIconFor(rarity),
                          label: rarity,
                          highlight: true,
                        ),
                        if (type != null && supertype != CardSupertype.trainer)
                          InfoChip(
                            icon: type!.typeIcon,
                            label: capitalize(type!.name),
                          ),
                        if (subtype != null && subtype!.isNotEmpty)
                          InfoChip(
                            icon: Icons.label_outline_rounded,
                            label: subtype!,
                          ),
                        if (finishChip != null)
                          InfoChip(
                            icon: Icons.auto_awesome_outlined,
                            label: finishChip!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showPrice) ...[
            const SizedBox(height: PokeBinderSpacing.sp4),
            _PricePanel(
              usd: priceUsd,
              php: pricePhp,
              updatedAt: priceUpdatedAt,
              caption: priceCaption,
            ),
          ],
          const SizedBox(height: PokeBinderSpacing.sp3),
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 12, color: PokeBinderColors.inkSoft),
              const SizedBox(width: PokeBinderSpacing.sp1),
              Flexible(
                child: Text(
                  'Details come from the card database',
                  style: PokeBinderText.listRowSubtitle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PricePanel extends StatelessWidget {
  final double? usd;
  final double? php;
  final DateTime? updatedAt;

  final String? caption;

  const _PricePanel({
    required this.usd,
    required this.php,
    required this.updatedAt,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrice = usd != null && php != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: PokeBinderSpacing.sp4,
        vertical: PokeBinderSpacing.sp3,
      ),
      decoration: BoxDecoration(
        color: PokeBinderColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PokeBinderColors.gold.withValues(alpha: 0.4),
        ),
      ),
      child: hasPrice
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caption == null
                            ? 'MARKET PRICE'
                            : 'MARKET PRICE · ${caption!.toUpperCase()}',
                        style: PokeBinderText.sectionLabel,
                      ),
                      const SizedBox(height: PokeBinderSpacing.sp0),
                      Text(formatPeso(php!), style: PokeBinderText.statNumber),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('US\$${usd!.toStringAsFixed(2)}',
                        style: PokeBinderText.rowTitle),
                    if (updatedAt != null) ...[
                      const SizedBox(height: PokeBinderSpacing.sp0),
                      Text('Updated ${shortDate(updatedAt!)}',
                          style: PokeBinderText.listRowSubtitle),
                    ],
                  ],
                ),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: PokeBinderColors.inkSoft),
                const SizedBox(width: PokeBinderSpacing.sp2),
                Expanded(
                  child: Text(
                    'No market price on file for this card. '
                    'Enter a value below.',
                    style: PokeBinderText.listRowSubtitle,
                  ),
                ),
              ],
            ),
    );
  }
}
