import 'package:flutter/material.dart';
import '../models/pokemon_card_data.dart';
import '../models/wishlist_entry.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/card_sort_controls.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokemon_card_widget.dart';
import 'wishlist_form_screen.dart';
import 'trade_list_add_card_screen.dart';
import 'trade_entry_form_screen.dart';
import 'wishlist_form_result.dart';

enum _WishlistSort { newest, oldest, nameAsc, priorityFirst, valueHigh }

extension on _WishlistSort {
  String get label {
    switch (this) {
      case _WishlistSort.newest:
        return 'Newest';
      case _WishlistSort.oldest:
        return 'Oldest';
      case _WishlistSort.nameAsc:
        return 'Name A–Z';
      case _WishlistSort.priorityFirst:
        return 'Priority';
      case _WishlistSort.valueHigh:
        return 'Value: High-Low';
    }
  }

  IconData get icon {
    switch (this) {
      case _WishlistSort.newest:
        return Icons.schedule_rounded;
      case _WishlistSort.oldest:
        return Icons.history_rounded;
      case _WishlistSort.nameAsc:
        return Icons.sort_by_alpha_rounded;
      case _WishlistSort.priorityFirst:
        return Icons.flag_rounded;
      case _WishlistSort.valueHigh:
        return Icons.payments_rounded;
    }
  }
}

/// Finds the catalog entry for [name], if any, so wishlist/trade rows can
/// show real card artwork instead of a generic placeholder.
PokemonCardData? _libraryMatch(String name) {
  final target = name.trim().toLowerCase();
  if (target.isEmpty) return null;
  for (final card in PokemonCardData.library) {
    if (card.name.toLowerCase() == target) return card;
  }
  return null;
}

String _formatValue(double value) {
  if (value >= 1000) return '₱${(value / 1000).toStringAsFixed(1)}k';
  return '₱${value.toStringAsFixed(0)}';
}

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final List<WishlistEntry> _entries = WishlistEntry.sampleEntries;
  WishlistEntryKind _kind = WishlistEntryKind.wishlist;
  _WishlistSort _sort = _WishlistSort.newest;
  WishlistPriority? _priorityFilter;
  String _query = '';

  int get _wishlistCount =>
      _entries.where((e) => e.kind == WishlistEntryKind.wishlist).length;

  int get _tradeCount =>
      _entries.where((e) => e.kind == WishlistEntryKind.trade).length;

  List<WishlistEntry> get _kindEntries =>
      _entries.where((e) => e.kind == _kind).toList();

  double get _kindValue =>
      _kindEntries.fold(0.0, (sum, e) => sum + e.estimatedValue * e.quantity);

  bool get _filtersActive => _query.isNotEmpty || _priorityFilter != null;

  List<WishlistEntry> get _filtered {
    final q = _query.toLowerCase().trim();
    final list = _entries.where((e) {
      final matchesKind = e.kind == _kind;
      final matchesQuery = q.isEmpty || e.name.toLowerCase().contains(q);
      final matchesPriority =
          _priorityFilter == null || e.priority == _priorityFilter;
      return matchesKind && matchesQuery && matchesPriority;
    }).toList();

    switch (_sort) {
      case _WishlistSort.newest:
        list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case _WishlistSort.oldest:
        list.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
        break;
      case _WishlistSort.nameAsc:
        list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _WishlistSort.priorityFirst:
        list.sort((a, b) => a.priority.index.compareTo(b.priority.index));
        break;
      case _WishlistSort.valueHigh:
        list.sort((a, b) => b.estimatedValue.compareTo(a.estimatedValue));
        break;
    }
    return list;
  }

  Future<void> _openAdd() async {
    if (_kind == WishlistEntryKind.trade) {
      final existingTradeEntries =
          _entries.where((e) => e.kind == WishlistEntryKind.trade).toList();
      final result = await Navigator.of(context).push<List<WishlistEntry>>(
        MaterialPageRoute(
          builder: (_) => TradeListAddCardScreen(
            initialEntries: existingTradeEntries,
          ),
        ),
      );
      if (result == null) return;
      setState(() {
        // Only the card-linked trade entries are managed by the picker;
        // anything typed in by hand elsewhere is left untouched.
        _entries.removeWhere((e) =>
            e.kind == WishlistEntryKind.trade && e.sourceCardId != null);
        _entries.addAll(result);
      });
      return;
    }

    final result = await Navigator.of(context).push<WishlistFormResult>(
      MaterialPageRoute(
        builder: (_) => const WishlistFormScreen(),
      ),
    );
    if (result == null || result.deleted) return;
    setState(() => _entries.add(result.entry!));
  }

  Future<void> _openEdit(WishlistEntry entry) async {
    final result = await Navigator.of(context).push<WishlistFormResult>(
      MaterialPageRoute(
        builder: (_) => entry.kind == WishlistEntryKind.wishlist
            ? WishlistFormScreen(existingEntry: entry)
            : TradeEntryFormScreen(existingEntry: entry),
      ),
    );
    if (result == null) return;

    setState(() {
      _entries.removeWhere((e) => e.id == entry.id);
      if (!result.deleted) _entries.add(result.entry!);
    });
  }

  Future<bool> _confirmRemove(WishlistEntry entry) async {
    final isWishlist = entry.kind == WishlistEntryKind.wishlist;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove entry?'),
        content: Text(
          'This removes "${entry.name}" from your '
          '${isWishlist ? 'wishlist' : 'trade list'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(
              Icons.delete_outline,
              size: 16,
              color: PokeBinderColors.danger,
            ),
            label: const Text(
              'Remove',
              style: TextStyle(color: PokeBinderColors.danger),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _removeEntry(WishlistEntry entry) {
    final removedIndex = _entries.indexOf(entry);
    setState(() => _entries.remove(entry));

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed "${entry.name}"'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => setState(() {
              final index = removedIndex.clamp(0, _entries.length);
              _entries.insert(index, entry);
            }),
          ),
        ),
      );
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _priorityFilter = null;
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
                label: '‹ Back',
                onTap: () => Navigator.of(context).maybePop(),
              ),
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
                labels: [
                  'Wishlist ($_wishlistCount)',
                  'Trade List ($_tradeCount)',
                ],
                onChanged: (i) => setState(() {
                  _kind = i == 0
                      ? WishlistEntryKind.wishlist
                      : WishlistEntryKind.trade;
                  _priorityFilter = null;
                }),
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),

              Row(
                children: [
                  Expanded(
                    child: _WishlistStatBox(
                      value: '${_kindEntries.length}',
                      label: isWishlist ? 'WANTED' : 'FOR TRADE',
                    ),
                  ),
                  const SizedBox(width: PokeBinderSpacing.sp2),
                  Expanded(
                    child: _WishlistStatBox(
                      value: _formatValue(_kindValue),
                      label: isWishlist ? 'EST. TO BUY' : 'EST. VALUE',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),

              CollectionSearchBar(
                hint: isWishlist
                    ? 'Search cards to wishlist…'
                    : 'Search cards to trade…',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),

              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: CardFilterChip(
                        label: 'All',
                        icon: Icons.apps_rounded,
                        active: _priorityFilter == null,
                        onTap: () => setState(() => _priorityFilter = null),
                      ),
                    ),
                    for (final priority in WishlistPriority.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: CardFilterChip(
                          label: priority.label,
                          icon: priority.icon,
                          active: _priorityFilter == priority,
                          onTap: () => setState(() => _priorityFilter = priority),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SHOWING ${filtered.length} '
                    '${filtered.length == 1 ? 'ITEM' : 'ITEMS'}',
                    style: PokeBinderText.resultCount,
                  ),
                  _WishlistSortSelector(
                    selected: _sort,
                    onChanged: (s) => setState(() => _sort = s),
                  ),
                ],
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),

              Expanded(
                child: filtered.isEmpty
                    ? _EmptyWishlistState(
                        isWishlist: isWishlist,
                        isFiltered: _filtersActive,
                        onClearFilters: _clearFilters,
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 1,
                          color: PokeBinderColors.ink.withValues(alpha: 0.06),
                        ),
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          return Dismissible(
                            key: ValueKey(entry.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _confirmRemove(entry),
                            onDismissed: (_) => _removeEntry(entry),
                            background: const _DismissBackground(),
                            child: _WishlistRow(
                              entry: entry,
                              onTap: () => _openEdit(entry),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),
              PillButton(
                label: isWishlist ? 'Add to Wishlist' : 'Add to Trade List',
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

class _WishlistStatBox extends StatelessWidget {
  final String value;
  final String label;

  const _WishlistStatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        boxShadow: kCardElevation,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: PokeBinderText.statNumber.copyWith(fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: PokeBinderText.statLabel),
        ],
      ),
    );
  }
}

class _WishlistSortSelector extends StatelessWidget {
  final _WishlistSort selected;
  final ValueChanged<_WishlistSort> onChanged;

  const _WishlistSortSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: PokeBinderColors.red.withValues(alpha: 0.06),
        splashColor: PokeBinderColors.red.withValues(alpha: 0.06),
        hoverColor: PokeBinderColors.red.withValues(alpha: 0.05),
      ),
      child: PopupMenuButton<_WishlistSort>(
        initialValue: selected,
        onSelected: onChanged,
        offset: const Offset(0, 32),
        color: PokeBinderColors.white,
        elevation: 8,
        shadowColor: PokeBinderColors.ink.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        ),
        constraints: const BoxConstraints(minWidth: 170),
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemBuilder: (context) => [
          for (final option in _WishlistSort.values)
            PopupMenuItem(
              value: option,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _WishlistSortMenuRow(
                option: option,
                selected: option == selected,
              ),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: PokeBinderColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('SORT: ${selected.label.toUpperCase()}',
                  style: PokeBinderText.resultCount),
              const SizedBox(width: 1),
              const Icon(
                Icons.expand_more_rounded,
                size: 15,
                color: PokeBinderColors.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WishlistSortMenuRow extends StatelessWidget {
  final _WishlistSort option;
  final bool selected;

  const _WishlistSortMenuRow({required this.option, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PokeBinderSpacing.sp2,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: selected ? PokeBinderColors.red.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(
            option.icon,
            size: 15,
            color: selected ? PokeBinderColors.redDeep : PokeBinderColors.inkSoft,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              option.label,
              style: PokeBinderText.chakraPetch(TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? PokeBinderColors.redDeep : PokeBinderColors.ink,
              )),
            ),
          ),
          if (selected)
            const Padding(
              padding: EdgeInsets.only(left: PokeBinderSpacing.sp1),
              child: Icon(
                Icons.check_rounded,
                size: 15,
                color: PokeBinderColors.red,
              ),
            ),
        ],
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: PokeBinderSpacing.sp3),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: PokeBinderColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: PokeBinderColors.danger,
        size: 20,
      ),
    );
  }
}

String _relativeAdded(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays >= 1) return '${diff.inDays}d ago';
  if (diff.inHours >= 1) return '${diff.inHours}h ago';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
  return 'Just now';
}

class _WishlistRow extends StatelessWidget {
  final WishlistEntry entry;
  final VoidCallback onTap;

  const _WishlistRow({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isWishlist = entry.kind == WishlistEntryKind.wishlist;
    final matchedCard = _libraryMatch(entry.name);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: PokeBinderSpacing.sp2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CardThumbnail(card: matchedCard, width: 36, height: 48),
                  Positioned(
                    left: -4,
                    top: -4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: entry.priority.color,
                        border: Border.all(color: PokeBinderColors.cream, width: 1.5),
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
                      entry.name,
                      overflow: TextOverflow.ellipsis,
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
                      overflow: TextOverflow.ellipsis,
                      style: PokeBinderText.listRowSubtitle,
                    ),
                    if (!isWishlist && entry.askingFor.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Wants: ${entry.askingFor}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PokeBinderText.cardMeta.copyWith(fontSize: 9),
                      ),
                    ],
                    if (entry.notes.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.notes,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PokeBinderText.cardMeta.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (entry.estimatedValue > 0) ...[
                    Text(
                      _formatValue(entry.estimatedValue),
                      style: PokeBinderText.cardMeta.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: PokeBinderColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(
                    _relativeAdded(entry.dateAdded),
                    style: PokeBinderText.cardMeta.copyWith(fontSize: 7.5),
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

class _EmptyWishlistState extends StatelessWidget {
  final bool isWishlist;
  final bool isFiltered;
  final VoidCallback onClearFilters;

  const _EmptyWishlistState({
    required this.isWishlist,
    required this.isFiltered,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PokeBinderColors.cream2.withValues(alpha: 0.6),
            ),
            child: Icon(
              isFiltered
                  ? Icons.filter_alt_off_rounded
                  : (isWishlist
                      ? Icons.star_border_rounded
                      : Icons.swap_horiz_rounded),
              size: 24,
              color: PokeBinderColors.goldDeep.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: PokeBinderSpacing.sp3),
          Text(
            isFiltered
                ? 'No cards match your filters.'
                : (isWishlist
                    ? 'No cards on your wishlist yet.'
                    : 'Nothing listed for trade yet.'),
            style: PokeBinderText.subtitle.copyWith(
              fontWeight: FontWeight.w600,
              color: PokeBinderColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            isFiltered
                ? 'Try a different search or priority.'
                : (isWishlist
                    ? "Add cards you're hoping to pull or pick up."
                    : "List dupes you're ready to trade away."),
            textAlign: TextAlign.center,
            style: PokeBinderText.subtitle,
          ),
          if (isFiltered) ...[
            const SizedBox(height: PokeBinderSpacing.sp3),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onClearFilters,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PokeBinderSpacing.sp3,
                    vertical: PokeBinderSpacing.sp1,
                  ),
                  child: Text('Clear filters', style: PokeBinderText.backLink),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}