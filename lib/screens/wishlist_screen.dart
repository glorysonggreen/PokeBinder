import 'package:flutter/material.dart';
import '../models/pokemon_card_data.dart';
import '../models/wishlist_entry.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import 'wishlist_form_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final List<WishlistEntry> _entries = WishlistEntry.sampleEntries;
  WishlistEntryKind _kind = WishlistEntryKind.wishlist;
  String _query = '';

  List<WishlistEntry> get _filtered {
    final q = _query.toLowerCase().trim();
    return _entries.where((e) {
      final matchesKind = e.kind == _kind;
      final matchesQuery = q.isEmpty || e.name.toLowerCase().contains(q);
      return matchesKind && matchesQuery;
    }).toList()
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
  }

  Future<void> _openAdd() async {
    final result = await Navigator.of(context).push<WishlistFormResult>(
      MaterialPageRoute(
        builder: (_) => WishlistFormScreen(initialKind: _kind),
      ),
    );
    if (result == null || result.deleted) return;
    setState(() => _entries.add(result.entry!));
  }

  Future<void> _openEdit(WishlistEntry entry) async {
    final result = await Navigator.of(context).push<WishlistFormResult>(
      MaterialPageRoute(
        builder: (_) => WishlistFormScreen(existingEntry: entry),
      ),
    );
    if (result == null) return;

    setState(() {
      _entries.removeWhere((e) => e.id == entry.id);
      if (!result.deleted) _entries.add(result.entry!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final isWishlist = _kind == WishlistEntryKind.wishlist;

    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PokeBinderSpacing.sp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackLink(
                label: '‹ More',
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text('WISHLIST & TRADE LIST', style: PokeBinderText.eyebrow),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('Cards You Want or Will Trade', style: PokeBinderText.heading),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text(
                'Keep track of pickups to chase and dupes to move.',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),

              SegmentedTabBar(
                index: isWishlist ? 0 : 1,
                labels: const ['Wishlist', 'Trade list'],
                onChanged: (i) => setState(
                  () => _kind = i == 0
                      ? WishlistEntryKind.wishlist
                      : WishlistEntryKind.trade,
                ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),

              CollectionSearchBar(
                hint: isWishlist
                    ? 'Search cards to wishlist…'
                    : 'Search cards to trade…',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),

              Expanded(
                child: filtered.isEmpty
                    ? _EmptyWishlistState(isWishlist: isWishlist)
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 1,
                          color: PokeBinderColors.ink.withValues(alpha: 0.06),
                        ),
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          return _WishlistRow(
                            entry: entry,
                            onTap: () => _openEdit(entry),
                          );
                        },
                      ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),
              PillButton(
                label: isWishlist ? '+ Add to wishlist' : '+ Add to trade list',
                icon: Icons.add,
                onTap: _openAdd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WishlistRow extends StatelessWidget {
  final WishlistEntry entry;
  final VoidCallback onTap;

  const _WishlistRow({required this.entry, required this.onTap});

  List<Color> get _thumbColors {
    final types = PokemonCardType.values;
    final index = entry.name.hashCode.abs() % types.length;
    return types[index].gradientColors;
  }

  @override
  Widget build(BuildContext context) {
    final isWishlist = entry.kind == WishlistEntryKind.wishlist;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: PokeBinderSpacing.sp2),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _thumbColors,
                  ),
                  boxShadow: kCardElevation,
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: PokeBinderText.listRowTitle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (entry.setName.isNotEmpty) entry.setName,
                        isWishlist
                            ? 'wanted ×${entry.quantity}'
                            : 'willing to trade ×${entry.quantity}',
                      ].join(' · '),
                      style: PokeBinderText.listRowSubtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp2),
              _KindTag(isWishlist: isWishlist),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindTag extends StatelessWidget {
  final bool isWishlist;

  const _KindTag({required this.isWishlist});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isWishlist
            ? const Color(0xFFFBEBCB)
            : PokeBinderColors.cream2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isWishlist ? 'Wishlist' : 'Trade',
        style: PokeBinderText.chakraPetch(TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
          color: isWishlist
              ? PokeBinderColors.goldDeep
              : PokeBinderColors.inkSoft,
        )),
      ),
    );
  }
}

class _EmptyWishlistState extends StatelessWidget {
  final bool isWishlist;

  const _EmptyWishlistState({required this.isWishlist});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWishlist ? Icons.star_border_rounded : Icons.swap_horiz_rounded,
            size: 30,
            color: PokeBinderColors.inkSoft.withValues(alpha: 0.4),
          ),
          const SizedBox(height: PokeBinderSpacing.sp2),
          Text(
            isWishlist
                ? 'No cards on your wishlist yet.'
                : 'Nothing listed for trade yet.',
            style: PokeBinderText.subtitle,
          ),
        ],
      ),
    );
  }
}
