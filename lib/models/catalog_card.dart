import 'package:flutter/foundation.dart';
import '../config/pricing.dart';
import 'enum_parsing.dart';
import 'pokemon_card_data.dart';

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

String finishLabel(String key) => _finishLabels[key] ?? key;

@immutable
class CatalogCard {
  final String id;
  final String name;
  final String setId;
  final String setName;

  final String number;

  final int? printedTotal;

  final String rarity;
  final String? rarityRaw;
  final PokemonCardType type;
  final CardSupertype supertype;
  final String? subtype;
  final String? imageSmall;
  final String? imageLarge;
  final double? marketPriceUsd;

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

  String? get defaultFinish => finishes.isEmpty ? null : finishes.first;

  double? priceUsdFor(String? finish) =>
      (finish == null ? null : finishPrices[finish]) ?? marketPriceUsd;

  String get displayNumber =>
      printedTotal == null ? number : '$number/$printedTotal';

  double? get marketPricePhp =>
      marketPriceUsd == null ? null : roundPeso(marketPriceUsd! * kUsdToPhpRate);

  String? get collectionImage => imageLarge ?? imageSmall;

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

final _numberParts = RegExp(r'^(\D*)(\d*)');

int compareByPrintedNumber(CatalogCard a, CatalogCard b) {
  final pa = _numberParts.firstMatch(a.number)!;
  final pb = _numberParts.firstMatch(b.number)!;
  final byPrefix = pa.group(1)!.compareTo(pb.group(1)!);
  if (byPrefix != 0) return byPrefix;
  final byDigits = (int.tryParse(pa.group(2)!) ?? 0)
      .compareTo(int.tryParse(pb.group(2)!) ?? 0);
  return byDigits != 0 ? byDigits : a.number.compareTo(b.number);
}
