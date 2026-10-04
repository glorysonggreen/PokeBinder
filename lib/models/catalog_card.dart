import 'package:flutter/foundation.dart';
import '../config/pricing.dart';
import 'enum_parsing.dart';
import 'pokemon_card_data.dart';

/// One expansion (e.g. Base Set) from the `card_sets` table.
@immutable
class CatalogSet {
  final String id;
  final String name;
  final String series;
  final DateTime? releaseDate;

  const CatalogSet({
    required this.id,
    required this.name,
    this.series = '',
    this.releaseDate,
  });

  factory CatalogSet.fromRow(Map<String, dynamic> row) {
    return CatalogSet(
      id: row['id'] as String,
      name: row['name'] as String,
      series: row['series'] as String? ?? '',
      releaseDate: row['release_date'] == null
          ? null
          : DateTime.tryParse(row['release_date'] as String),
    );
  }
}

/// The printings the price source reports, most ordinary first. The first one
/// a card has is its default finish (and matches its `market_price_usd`).
const _finishOrder = [
  'normal',
  'unlimitedNormal',
  'holofoil',
  'unlimitedHolofoil',
  'reverseHolofoil',
  '1stEditionNormal',
  '1stEditionHolofoil',
];

const _finishLabels = {
  'normal': 'Normal',
  'unlimitedNormal': 'Unlimited',
  'holofoil': 'Holofoil',
  'unlimitedHolofoil': 'Unlimited Holo',
  'reverseHolofoil': 'Reverse Holo',
  '1stEditionNormal': '1st Edition',
  '1stEditionHolofoil': '1st Ed. Holo',
};

/// A friendly name for a finish key such as `reverseHolofoil`.
String finishLabel(String key) => _finishLabels[key] ?? key;

/// One printed card from the `card_catalog` table: the reference data the
/// user picks from instead of typing a name, set, number and rarity by hand.
///
/// This is read-only reference data shared by every account. A card in
/// someone's collection ([PokemonCardData]) copies these fields at the moment
/// it is added and keeps a [PokemonCardData.catalogId] link back here.
@immutable
class CatalogCard {
  final String id;
  final String name;
  final String setId;
  final String setName;

  /// The number as printed in the set, e.g. `4`.
  final String number;

  /// How many cards the set prints, e.g. `102` — null when unknown.
  final int? printedTotal;

  /// One of [kRarityOptions] (the source's own wording is in [rarityRaw]).
  final String rarity;
  final String? rarityRaw;
  final PokemonCardType type;
  final CardSupertype supertype;
  final String? subtype;
  final String? imageSmall;
  final String? imageLarge;
  final double? marketPriceUsd;

  /// Market price in US dollars for each printing, keyed like `holofoil`.
  /// Empty when the catalog only knows one price (see [marketPriceUsd]).
  final Map<String, double> finishPrices;
  final DateTime? priceUpdatedAt;

  const CatalogCard({
    required this.id,
    required this.name,
    required this.setId,
    required this.setName,
    required this.number,
    this.printedTotal,
    required this.rarity,
    this.rarityRaw,
    required this.type,
    required this.supertype,
    this.subtype,
    this.imageSmall,
    this.imageLarge,
    this.marketPriceUsd,
    this.finishPrices = const {},
    this.priceUpdatedAt,
  });

  /// The printings this card has a price for, most ordinary first.
  List<String> get finishes {
    final keys = finishPrices.keys.toList();
    int rank(String k) {
      final i = _finishOrder.indexOf(k);
      return i == -1 ? _finishOrder.length : i;
    }

    keys.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : a.compareTo(b);
    });
    return keys;
  }

  /// The finish used until the person picks another, or null when the catalog
  /// has no per-finish prices.
  String? get defaultFinish => finishes.isEmpty ? null : finishes.first;

  /// The dollar price for [finish], falling back to [marketPriceUsd].
  double? priceUsdFor(String? finish) =>
      (finish == null ? null : finishPrices[finish]) ?? marketPriceUsd;

  /// `4/102` when the set size is known, otherwise just `4` — the same
  /// format the rest of the app uses for [PokemonCardData.cardNumber].
  String get displayNumber =>
      printedTotal == null ? number : '$number/$printedTotal';

  /// The suggested value in pesos, or null when the catalog has no price.
  double? get marketPricePhp =>
      marketPriceUsd == null ? null : roundPeso(marketPriceUsd! * kUsdToPhpRate);

  /// Art used for the owned copy: the large image looks sharp on the card
  /// details screen, the small one is used for list thumbnails.
  String? get collectionImage => imageLarge ?? imageSmall;

  /// Expects a row selected with `*, card_sets(name, printed_total)`.
  factory CatalogCard.fromRow(Map<String, dynamic> row) {
    final set = row['card_sets'] as Map<String, dynamic>?;
    return CatalogCard(
      id: row['id'] as String,
      name: row['name'] as String,
      setId: row['set_id'] as String,
      setName: set?['name'] as String? ?? '',
      number: row['number'] as String? ?? '',
      printedTotal: (set?['printed_total'] as num?)?.toInt(),
      rarity: row['rarity'] as String? ?? 'Other/Additional Rarities',
      rarityRaw: row['rarity_raw'] as String?,
      type: enumByNameOr(PokemonCardType.values, row['type'] as String?,
          PokemonCardType.colorless),
      supertype: enumByNameOr(CardSupertype.values,
          row['supertype'] as String?, CardSupertype.pokemon),
      subtype: row['subtype'] as String?,
      imageSmall: row['image_small'] as String?,
      imageLarge: row['image_large'] as String?,
      marketPriceUsd: (row['market_price_usd'] as num?)?.toDouble(),
      finishPrices: _parseFinishPrices(row['prices']),
      priceUpdatedAt: row['price_updated_at'] == null
          ? null
          : DateTime.tryParse(row['price_updated_at'] as String)?.toLocal(),
    );
  }
}

Map<String, double> _parseFinishPrices(Object? raw) {
  if (raw is! Map) return const {};
  final out = <String, double>{};
  raw.forEach((key, value) {
    if (key is String && value is num) out[key] = value.toDouble();
  });
  return out;
}

/// Splits a printed number into its letters and digits, so `SWSH001` sorts
/// after `99` and `10` after `9`.
final _numberParts = RegExp(r'^(\D*)(\d*)');

/// Orders cards by printed number: 1, 2, ... 10, then lettered ones (SWSH001).
int compareByPrintedNumber(CatalogCard a, CatalogCard b) {
  final pa = _numberParts.firstMatch(a.number)!;
  final pb = _numberParts.firstMatch(b.number)!;
  final byPrefix = pa.group(1)!.compareTo(pb.group(1)!);
  if (byPrefix != 0) return byPrefix;
  final byDigits = (int.tryParse(pa.group(2)!) ?? 0)
      .compareTo(int.tryParse(pb.group(2)!) ?? 0);
  return byDigits != 0 ? byDigits : a.number.compareTo(b.number);
}
