import 'package:flutter/material.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import '../models/wishlist_entry.dart';
import '../theme/pokebinder_theme.dart';
import 'min_tap_target.dart';
import 'pokebinder_controls.dart';
import 'pokebinder_toast.dart';

String _cardDeletionMessage(List<PokemonCardData> cards) {
  final ids = cards.map((c) => c.id).toSet();
  final single = cards.length == 1;
  final inTradeList = WishlistEntry.library.any(
    (e) => e.sourceCardId != null && ids.contains(e.sourceCardId),
  );
  final inDecks = DeckData.library.any(
    (d) => d.cards.any((c) => ids.contains(c.cardId)),
  );

  final subject = single ? '"${cards.first.name}"' : '${cards.length} cards';
  final pronoun = single ? 'It' : 'They';
  final buffer = StringBuffer('This removes $subject from your collection.');
  if (inTradeList && inDecks) {
    buffer.write(' $pronoun will also come off your trade list and decks.');
  } else if (inTradeList) {
    buffer.write(' $pronoun will also come off your trade list.');
  } else if (inDecks) {
    buffer.write(' $pronoun will also come out of your decks.');
  }
  buffer.write(" This can't be undone.");
  return buffer.toString();
}

Future<bool> confirmCardDeletion(
  BuildContext context,
  List<PokemonCardData> cards,
) {
  return confirmDestructive(
    context,
    title: cards.length == 1 ? 'Delete card?' : 'Delete ${cards.length} cards?',
    message: _cardDeletionMessage(cards),
    confirmLabel: 'Delete',
  );
}

void showCardsDeletedToast(BuildContext context, List<PokemonCardData> cards) {
  PokeBinderToast.show(
    context,
    cards.length == 1
        ? 'Deleted ${cards.first.name}'
        : 'Deleted ${cards.length} cards',
    kind: ToastKind.success,
  );
}

class CardSelectAction extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onTap;

  const CardSelectAction({
    super.key,
    this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = PokeBinderText.backLink.color;
    return MinTapTarget(
      onTap: onTap,
      size: kMinTapTarget,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PokeBinderSpacing.sp2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: PokeBinderSpacing.sp1),
            ],
            Text(label, style: PokeBinderText.backLink),
          ],
        ),
      ),
    );
  }
}

class CardSelectionHeader extends StatelessWidget {
  final int selectedCount;
  final bool allSelected;
  final VoidCallback onSelectAll;
  final VoidCallback onCancel;

  const CardSelectionHeader({
    super.key,
    required this.selectedCount,
    required this.allSelected,
    required this.onSelectAll,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$selectedCount SELECTED',
            style: PokeBinderText.resultCount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!allSelected)
          CardSelectAction(label: 'Select all', onTap: onSelectAll),
        CardSelectAction(label: 'Cancel', onTap: onCancel),
      ],
    );
  }
}

class CardSelectionMark extends StatelessWidget {
  final bool selected;

  const CardSelectionMark({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedOpacity(
          opacity: selected ? 1 : 0,
          duration: const Duration(milliseconds: 120),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: PokeBinderColors.red.withValues(alpha: 0.12),
              border: Border.all(color: PokeBinderColors.red, width: 2),
            ),
          ),
        ),
        Positioned(
          top: PokeBinderSpacing.sp1,
          right: PokeBinderSpacing.sp1,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? PokeBinderColors.red
                  : PokeBinderColors.white.withValues(alpha: 0.85),
              border: Border.all(
                color: selected
                    ? PokeBinderColors.red
                    : PokeBinderColors.ink.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: selected
                ? const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: PokeBinderColors.white,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class CardSelectionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onDelete;
  final VoidCallback? onRemoveFromBinder;

  const CardSelectionBar({
    super.key,
    required this.selectedCount,
    required this.onDelete,
    this.onRemoveFromBinder,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = selectedCount > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: PokeBinderSpacing.sp3),
      padding: const EdgeInsets.all(PokeBinderSpacing.sp2),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        boxShadow: kCardElevation,
      ),
      child: Row(
        children: [
          if (onRemoveFromBinder != null) ...[
            Expanded(
              child: _BarButton(
                label: 'Remove',
                icon: Icons.remove_circle_outline,
                enabled: enabled,
                onTap: onRemoveFromBinder!,
              ),
            ),
            const SizedBox(width: PokeBinderSpacing.sp2),
          ],
          Expanded(
            child: _BarButton(
              label: enabled ? 'Delete ($selectedCount)' : 'Delete',
              icon: Icons.delete_outline,
              danger: true,
              enabled: enabled,
              onTap: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool danger;
  final bool enabled;
  final VoidCallback onTap;

  const _BarButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        danger ? PokeBinderColors.white : PokeBinderColors.redDeep;
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.45,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: danger ? PokeBinderColors.danger : PokeBinderColors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? onTap : null,
          child: Container(
            height: kMinTapTarget,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: danger
                  ? null
                  : Border.all(
                      color: PokeBinderColors.red.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: PokeBinderSpacing.sp2),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PokeBinderText.buttonLabel.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
