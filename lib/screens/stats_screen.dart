import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokemon_card_widget.dart';
import 'card_details_screen.dart';
import 'card_form_screen.dart';

const _kDonutColors = [
  PokeBinderColors.red,
  PokeBinderColors.gold,
  PokeBinderColors.teal,
  Color(0xFF7A6DB0),
  Color(0xFF4F8F47),
  Color(0xFFA8531F),
];

class _RarityStat {
  final String rarity;
  final double value;

  const _RarityStat(this.rarity, this.value);
}

class _SetStat {
  final String setName;
  final int count;

  const _SetStat(this.setName, this.count);
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final List<BinderData> _binders = BinderData.sampleBinders;

  List<PokemonCardData> get _library => PokemonCardData.library;

  int get _totalCards =>
      _library.fold(0, (sum, c) => sum + c.quantityOwned);

  double get _totalValue => _library.fold(
        0.0,
        (sum, c) => sum + c.estimatedValue * c.quantityOwned,
      );

  int get _setCount => _library.map((c) => c.setName).toSet().length;

  List<_RarityStat> get _valueByRarity {
    final totals = <String, double>{};
    for (final card in _library) {
      totals[card.rarity] =
          (totals[card.rarity] ?? 0) + card.estimatedValue * card.quantityOwned;
    }
    final stats = totals.entries
        .map((e) => _RarityStat(e.key, e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return stats.take(6).toList();
  }

  List<_SetStat> get _cardsBySet {
    final counts = <String, int>{};
    for (final card in _library) {
      counts[card.setName] = (counts[card.setName] ?? 0) + card.quantityOwned;
    }
    final stats = counts.entries
        .map((e) => _SetStat(e.key, e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return stats;
  }

  List<PokemonCardData> get _topValueCards {
    final sorted = [..._library]
      ..sort((a, b) => (b.estimatedValue * b.quantityOwned)
          .compareTo(a.estimatedValue * a.quantityOwned));
    return sorted.take(3).toList();
  }

  String _formatCurrency(double value) {
    if (value >= 1000) {
      return '₱${(value / 1000).toStringAsFixed(1)}k';
    }
    return '₱${value.toStringAsFixed(0)}';
  }

  Future<void> _openCardDetails(PokemonCardData card) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardDetailsScreen(
          card: card,
          binders: _binders,
          onSave: _handleCardSaved,
        ),
      ),
    );
  }

  void _handleCardSaved(PokemonCardData oldCard, CardFormResult result) {
    setState(() {
      final index = PokemonCardData.library.indexWhere((c) => c.id == oldCard.id);
      if (index == -1) return;
      if (result.deleted) {
        PokemonCardData.library.removeAt(index);
      } else {
        PokemonCardData.library[index] = result.card!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rarityStats = _valueByRarity;
    final setStats = _cardsBySet;

    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: PokeBinderSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackLink(
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('Your Collection', style: PokeBinderText.heading),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text(
                'Value, rarity, and set breakdown across every binder.',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),

              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      value: '$_totalCards',
                      label: 'Cards',
                    ),
                  ),
                  const SizedBox(width: PokeBinderSpacing.sp2),
                  Expanded(
                    child: _StatBox(
                      value: _formatCurrency(_totalValue),
                      label: 'Value',
                    ),
                  ),
                  const SizedBox(width: PokeBinderSpacing.sp2),
                  Expanded(
                    child: _StatBox(
                      value: '$_setCount',
                      label: 'Sets',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),

              Text('VALUE BY RARITY', style: PokeBinderText.sectionLabel),
              const SizedBox(height: PokeBinderSpacing.sp2),
              _ValueByRarityPanel(stats: rarityStats),
              const SizedBox(height: PokeBinderSpacing.sp4),

              Text('CARDS BY SET', style: PokeBinderText.sectionLabel),
              const SizedBox(height: PokeBinderSpacing.sp2),
              _CardsBySetPanel(stats: setStats),
              const SizedBox(height: PokeBinderSpacing.sp4),

              Text('TOP VALUE CARDS', style: PokeBinderText.sectionLabel),
              const SizedBox(height: PokeBinderSpacing.sp2),
              _TopValuePanel(cards: _topValueCards, onTapCard: _openCardDetails),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: PokeBinderSpacing.sp4,
        horizontal: PokeBinderSpacing.sp1,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PokeBinderColors.white, Color(0xFFFBF7EC)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        boxShadow: kCardElevation,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: PokeBinderText.statNumberSm),
          const SizedBox(height: PokeBinderSpacing.sp1),
          Text(
            label.toUpperCase(),
            style: PokeBinderText.statLabel.copyWith(letterSpacing: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ValueByRarityPanel extends StatelessWidget {
  final List<_RarityStat> stats;

  const _ValueByRarityPanel({required this.stats});

  static const _barGradients = [
    PokeBinderColors.goldGradient,
    PokeBinderColors.redGradient,
    PokeBinderColors.tealGradient,
    PokeBinderColors.slateGradient,
  ];

  double _barFraction(double value, double maxValue) {
    if (maxValue <= 0) return 0.06;
    return (value / maxValue).clamp(0.06, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const _EmptyPanel(message: 'Add cards to see a rarity breakdown.');
    }

    final maxValue = stats.map((s) => s.value).reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(PokeBinderSpacing.sp3),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        boxShadow: kCardElevation,
      ),
      child: SizedBox(
        height: 128,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < stats.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PokeBinderSpacing.sp1,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        stats[i].value >= 1000
                            ? '${(stats[i].value / 1000).toStringAsFixed(1)}k'
                            : stats[i].value.toStringAsFixed(0),
                        textAlign: TextAlign.center,
                        style: PokeBinderText.cardMeta.copyWith(fontSize: 9),
                      ),
                      const SizedBox(height: PokeBinderSpacing.sp1),
                      Container(
                        height: 78 * _barFraction(stats[i].value, maxValue),
                        decoration: BoxDecoration(
                          gradient: _barGradients[i % _barGradients.length],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(5),
                            topRight: Radius.circular(5),
                          ),
                        ),
                      ),
                      const SizedBox(height: PokeBinderSpacing.sp2),
                      Text(
                        stats[i].rarity,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: PokeBinderText.cardMeta,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardsBySetPanel extends StatelessWidget {
  final List<_SetStat> stats;

  const _CardsBySetPanel({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const _EmptyPanel(message: 'Add cards to see a set breakdown.');
    }

    final total = stats.fold<int>(0, (sum, s) => sum + s.count);

    return Container(
      padding: const EdgeInsets.all(PokeBinderSpacing.sp3),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        boxShadow: kCardElevation,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: CustomPaint(
              painter: _DonutPainter(
                values: [for (final s in stats) s.count.toDouble()],
                colors: _kDonutColors,
              ),
              child: Center(
                child: Text(
                  '$total',
                  style: PokeBinderText.statNumberSm,
                ),
              ),
            ),
          ),
          const SizedBox(width: PokeBinderSpacing.sp4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < stats.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == stats.length - 2 ? 0 : PokeBinderSpacing.sp2,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _kDonutColors[i % _kDonutColors.length],
                          ),
                        ),
                        const SizedBox(width: PokeBinderSpacing.sp1),
                        Expanded(
                          child: Text(
                            stats[i].setName,
                            overflow: TextOverflow.ellipsis,
                            style: PokeBinderText.listRowSubtitle
                                .copyWith(color: PokeBinderColors.ink),
                          ),
                        ),
                        Text(
                          '${(stats[i].count / total * 100).round()}%',
                          style: PokeBinderText.listRowSubtitle,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  const _DonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, v) => sum + v);
    if (total <= 0) return;

    final rect = Offset.zero & size;
    final strokeWidth = size.shortestSide * 0.26;
    var startAngle = -math.pi / 2;

    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}

class _TopValuePanel extends StatelessWidget {
  final List<PokemonCardData> cards;
  final ValueChanged<PokemonCardData> onTapCard;

  const _TopValuePanel({required this.cards, required this.onTapCard});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const _EmptyPanel(message: 'Your priciest cards will show up here.');
    }

    return Container(
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        boxShadow: kCardElevation,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i != 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 114,
                  color: PokeBinderColors.ink.withValues(alpha: 0.06),
                ),
              _TopValueRow(
                card: cards[i],
                rank: i + 1,
                onTap: () => onTapCard(cards[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card row for a top-value card, styled to match [_ScanRow] on the
/// Scanner screen: same thumbnail size/frame, chakraPetch bold name,
/// `set · #number` subtitle line, and a [Wrap] of small icon+label tags
/// (rarity, condition). The rank badge overlays the thumbnail corner in
/// place of the scan row's "newest" dot, and the estimated value replaces
/// the relative-time badge. Tapping the row opens [CardDetailsScreen] for
/// the card, and any saved notes are shown below the tags as an italic
/// description line, matching the notes line on the Wishlist screen's
/// card rows.
class _TopValueRow extends StatelessWidget {
  final PokemonCardData card;
  final int rank;
  final VoidCallback onTap;

  const _TopValueRow({required this.card, required this.rank, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(PokeBinderSpacing.sp3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: PokeBinderColors.ink.withValues(alpha: 0.08),
                      ),
                      boxShadow: kCardElevation,
                    ),
                    child: CardThumbnail(
                      card: card,
                      width: 92,
                      height: 127,
                      borderRadius: 5,
                    ),
                  ),
                  Positioned(
                    top: -6,
                    left: -6,
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: card.type.gradientColors,
                        ),
                        border:
                            Border.all(color: PokeBinderColors.white, width: 1.5),
                        boxShadow: kCardElevation,
                      ),
                      child: Text(
                        '$rank',
                        style: PokeBinderText.chipLabelActive,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: PokeBinderSpacing.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      style: PokeBinderText.rowTitle,
                    ),
                    const SizedBox(height: PokeBinderSpacing.sp1),
                    Text(
                      '${card.setName} · #${card.cardNumber}',
                      style: PokeBinderText.listRowSubtitle,
                    ),
                    const SizedBox(height: PokeBinderSpacing.sp2),
                    Wrap(
                      spacing: PokeBinderSpacing.sp2,
                      runSpacing: PokeBinderSpacing.sp1,
                      children: [
                        _RarityTag(rarity: card.rarity),
                        _ConditionTag(code: card.condition),
                      ],
                    ),
                    if (card.notes.isNotEmpty) ...[
                      const SizedBox(height: PokeBinderSpacing.sp1),
                      Text(
                        card.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: PokeBinderText.listRowSubtitle.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp2),
              Text(
                '₱${(card.estimatedValue * card.quantityOwned).toStringAsFixed(0)}',
                style: PokeBinderText.buttonGhostLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small icon + label pairing for a card's rarity, matching the tag used
/// on the Scanner screen's recent-scan rows.
class _RarityTag extends StatelessWidget {
  final String rarity;

  const _RarityTag({required this.rarity});

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

/// Small icon + label pairing for a card's condition, matching the tag
/// used on the Scanner screen's recent-scan rows.
class _ConditionTag extends StatelessWidget {
  final String code;

  const _ConditionTag({required this.code});

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

class _EmptyPanel extends StatelessWidget {
  final String message;

  const _EmptyPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PokeBinderSpacing.sp4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: PokeBinderText.subtitle,
      ),
    );
  }
}