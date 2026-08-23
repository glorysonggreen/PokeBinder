import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/interactive_3d_card.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokemon_card_widget.dart';
import 'card_form_screen.dart';

class CardDetailsScreen extends StatefulWidget {
  final PokemonCardData card;
  final List<BinderData> binders;

  /// Called with the card's state *before* this edit and the form result
  /// describing the edit, so the caller (which owns the actual binder/card
  /// data) can place the updated card correctly — including moving it to a
  /// different binder or page if that's what changed.
  final void Function(PokemonCardData oldCard, CardFormResult result) onSave;

  const CardDetailsScreen({
    super.key,
    required this.card,
    required this.binders,
    required this.onSave,
  });

  @override
  State<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends State<CardDetailsScreen> {
  late PokemonCardData _card = widget.card;

  Future<void> _editCard() async {
    final currentBinder = widget.binders.firstWhere(
      (b) => b.name == _card.binderName,
      orElse: () => widget.binders.first,
    );

    final result = await Navigator.of(context).push<CardFormResult>(
      MaterialPageRoute(
        builder: (_) => CardFormScreen(
          existingCard: _card,
          binders: widget.binders,
          defaultBinderId: currentBinder.id,
          defaultPageNumber: _card.page,
        ),
      ),
    );
    if (result == null) return;

    widget.onSave(_card, result);

    if (result.deleted) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() => _card = result.card!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved changes to ${result.card!.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;

    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            PokeBinderSpacing.sp4,
            PokeBinderSpacing.sp4,
            PokeBinderSpacing.sp4,
            PokeBinderSpacing.sp6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackLink(onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('CARD DETAILS', style: PokeBinderText.eyebrow),
              const SizedBox(height: PokeBinderSpacing.sp4),

              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = math.min(
                      constraints.maxWidth * kPokemonCardWidthFraction,
                      kPokemonCardMaxWidth,
                    );
                    final cardHeight = cardWidth / kPokemonCardImageAspectRatio;
                    final bufferWidth =
                        cardWidth * kCardInteractionHeightBuffer;
                    final bufferHeight =
                        cardHeight * kCardInteractionHeightBuffer;

                    return ClipRect(
                      child: SizedBox(
                        width: bufferWidth,
                        height: bufferHeight,
                        child: Center(
                          child: SizedBox(
                            width: cardWidth,
                            height: cardHeight,
                            child: Interactive3DCard(
                              back: const PokemonCardBack(),
                              child: PokemonCard(card: card),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),

              Text(card.name, style: PokeBinderText.heading),
              const SizedBox(height: 2),
              Text(
                '${card.setName} · #${card.cardNumber} · ${card.rarity}',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),

              Row(
                children: [
                  Expanded(
                    child: _FieldTile(
                      label: 'Qty owned',
                      value: '${card.quantityOwned}',
                    ),
                  ),
                  const SizedBox(width: PokeBinderSpacing.sp2),
                  Expanded(
                    child: _FieldTile(
                      label: 'Condition',
                      value: card.condition,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Row(
                children: [
                  Expanded(
                    child: _FieldTile(
                      label: 'Binder',
                      value: card.binderName,
                    ),
                  ),
                  const SizedBox(width: PokeBinderSpacing.sp2),
                  Expanded(
                    child: _FieldTile(label: 'Page', value: '${card.page}'),
                  ),
                ],
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),

              _StatBox(
                label: 'EST. MARKET VALUE',
                value: '₱${card.estimatedValue.toStringAsFixed(0)}',
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),

              if (card.notes.isNotEmpty)
                _FieldTile(
                  label: 'Notes',
                  value: card.notes,
                  minHeight: 42,
                  stacked: true,
                ),
              const SizedBox(height: PokeBinderSpacing.sp4),

              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: 'Edit',
                      ghost: true,
                      onTap: _editCard,
                    ),
                  ),
                  const SizedBox(width: PokeBinderSpacing.sp2),
                  Expanded(
                    child: PillButton(
                      label: 'Add to deck',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added ${card.name} to deck')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  final String label;
  final String value;
  final double? minHeight;
  final bool stacked;

  const _FieldTile({
    required this.label,
    required this.value,
    this.minHeight,
    this.stacked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: minHeight != null
          ? BoxConstraints(minHeight: minHeight!)
          : null,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: PokeBinderColors.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
      ),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$label:', style: PokeBinderText.fieldLabel),
                const SizedBox(height: 2),
                Text(value, style: PokeBinderText.fieldValue),
              ],
            )
          : Row(
              children: [
                Text('$label ', style: PokeBinderText.fieldLabel),
                Text(value, style: PokeBinderText.fieldValue),
              ],
            ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PokeBinderColors.white, Color(0xFFFBF7EC)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: PokeBinderText.statLabel),
          const SizedBox(height: 3),
          Text(value, style: PokeBinderText.statNumber),
        ],
      ),
    );
  }
}