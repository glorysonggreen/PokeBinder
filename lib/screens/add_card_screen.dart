import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/catalog_card.dart';
import '../models/pokemon_card_data.dart';
import '../services/binder_repository.dart';
import '../services/card_repository.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/catalog_picker.dart';
import 'card_form_screen.dart';
import '../services/audio_service.dart';
import '../widgets/pokebinder_toast.dart';

PokemonCardData? saveNewCard(CardFormResult result) {
  final card = result.card!;
  final library = PokemonCardData.library;
  final index = library.indexWhere((c) => c.id == card.id);
  PokemonCardData? replaced;
  if (index == -1) {
    _growBinderIfNeeded(result.binderId!, result.pageIndex!);
    library.add(card);
  } else {
    replaced = library[index];
    library[index] = card;
  }
  CardRepository.upsert(card);
  return replaced;
}

void _growBinderIfNeeded(String binderId, int pageIndex) {
  if (binderId == kUnassignedBinderId) return;
  final binders = BinderData.library;
  final index = binders.indexWhere((b) => b.id == binderId);
  if (index == -1) return;
  final binder = binders[index];
  if (pageIndex >= binder.pageCount) {
    binders[index] = binder.copyWith(pageCount: pageIndex + 1);
    BinderRepository.upsert(binders[index]);
  }
}

class AddCardScreen extends StatefulWidget {
  final VoidCallback onCardAdded;

  const AddCardScreen({super.key, required this.onCardAdded});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  Future<void> _pick(CatalogCard card) async {
    final result = await Navigator.of(context).push<CardFormResult>(
      MaterialPageRoute(
        builder: (_) => CardFormScreen(
          catalogCard: card,
          binders: BinderData.library,
          defaultBinderId: kUnassignedBinderId,
        ),
      ),
    );
    _handleResult(result);
  }

  void _handleResult(CardFormResult? result) {
    if (!mounted || result == null || result.deleted || result.card == null) {
      return;
    }
    final card = result.card!;
    final replaced = saveNewCard(result);
    PokeBinderAudio.play(Sfx.cardAdd);
    if (isChaseRarity(card.rarity)) {
      PokeBinderAudio.play(
        Sfx.rare,
        delay: const Duration(milliseconds: 450),
      );
    }
    setState(() {});
    widget.onCardAdded();

    PokeBinderToast.show(
      context,
      replaced == null
          ? 'Added ${card.name} to your collection.'
          : 'Now you own ${card.quantityOwned} of ${card.name}.',
      kind: ToastKind.success,
      actionLabel: 'Undo',
      onAction: () => _undoAdd(card, replaced),
    );
  }

  void _undoAdd(PokemonCardData card, PokemonCardData? replaced) {
    if (replaced == null) {
      CardRepository.delete(card.id);
    } else {
      final library = PokemonCardData.library;
      final index = library.indexWhere((c) => c.id == card.id);
      if (index != -1) {
        library[index] = replaced;
      } else {
        library.add(replaced);
      }
      CardRepository.upsert(replaced);
    }
    if (mounted) {
      setState(() {});
      widget.onCardAdded();
    }
  }

  Map<String, int> _ownedByCatalogId() {
    final owned = <String, int>{};
    for (final card in PokemonCardData.library) {
      final id = card.catalogId;
      if (id != null) owned[id] = (owned[id] ?? 0) + card.quantityOwned;
    }
    return owned;
  }

  @override
  Widget build(BuildContext context) {
    return CatalogPicker(
      header: [
        Text('ADD A CARD', style: PokeBinderText.eyebrow),
        const SizedBox(height: PokeBinderSpacing.sp2),
        Text('Find Your Card', style: PokeBinderText.heading),
        const SizedBox(height: PokeBinderSpacing.sp2),
        Text(
          'Pick it from the card database so the name, set, artwork and '
          'price are always correct.',
          style: PokeBinderText.subtitle,
        ),
        const SizedBox(height: PokeBinderSpacing.sp4),
      ],
      counts: _ownedByCatalogId,
      onPick: _pick,
    );
  }
}
