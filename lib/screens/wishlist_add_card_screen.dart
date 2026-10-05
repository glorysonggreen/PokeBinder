import 'package:flutter/material.dart';
import '../models/catalog_card.dart';
import '../models/wishlist_entry.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/catalog_picker.dart';
import '../widgets/pokebinder_controls.dart';
import 'wishlist_form_result.dart';
import 'wishlist_form_screen.dart';

class WishlistAddCardScreen extends StatelessWidget {
  final Iterable<WishlistEntry> entries;

  const WishlistAddCardScreen({super.key, required this.entries});

  Map<String, int> _wishedByCatalogId() {
    final wished = <String, int>{};
    for (final entry in entries) {
      final id = entry.catalogId;
      if (id != null && entry.kind == WishlistEntryKind.wishlist) {
        wished[id] = (wished[id] ?? 0) + entry.quantity;
      }
    }
    return wished;
  }

  Future<void> _pick(BuildContext context, CatalogCard card) async {
    final result = await Navigator.of(context).push<WishlistFormResult>(
      MaterialPageRoute(
        builder: (_) => WishlistFormScreen(catalogCard: card),
      ),
    );
    final entry = result?.entry;
    if (entry != null && context.mounted) {
      Navigator.of(context).pop(entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CatalogPicker(
      header: [
        BackLink(onTap: () => Navigator.of(context).maybePop()),
        const SizedBox(height: PokeBinderSpacing.sp2),
        Text('Find Your Card', style: PokeBinderText.heading),
        const SizedBox(height: PokeBinderSpacing.sp1),
        Text(
          'Pick the card you want from the card database so the name, set, '
          'artwork and price are always correct.',
          style: PokeBinderText.subtitle,
        ),
        const SizedBox(height: PokeBinderSpacing.sp3),
      ],
      counts: _wishedByCatalogId,
      countLabel: 'WISHED',
      onPick: (card) => _pick(context, card),
    );
  }
}
