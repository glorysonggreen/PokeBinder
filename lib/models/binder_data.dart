import 'package:flutter/foundation.dart';
import 'pokemon_card_data.dart';

const kUnassignedBinderId = '__unassigned__';

/// The `binderName` a card carries while it isn't placed in any binder.
/// This — not a card's supertype or anything else — is what makes a card
/// count as "unassigned".
const kUnassignedBinderName = 'Unassigned';
const kUncategorized = '';

@immutable
class BinderData {
  final String id;
  final String name;
  final String description;

  /// How many pages this binder has. This is the only thing about a
  /// binder's contents that's actually stored here — which cards sit on
  /// which page is derived from [PokemonCardData.library] (see [pages]),
  /// so a binder can have empty trailing pages before any card is placed
  /// on them.
  final int pageCount;
  final int slotsPerPage;
  final String category;
  final bool isPinned;
  final DateTime? createdAt;

  const BinderData({
    required this.id,
    required this.name,
    this.pageCount = 1,
    this.description = '',
    this.slotsPerPage = 9,
    this.category = kUncategorized,
    this.isPinned = false,
    this.createdAt,
  });

  DateTime get createdAtOrEpoch =>
      createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// This binder's cards, grouped by page, read live from
  /// [PokemonCardData.library] — the single source of truth for where
  /// every card lives. A binder never keeps its own copy of a card: a
  /// card belongs to this binder exactly when its `binderName` matches
  /// [name], and sits on the page numbered by its `page` field.
  List<List<PokemonCardData>> get pages {
    final result = List.generate(pageCount, (_) => <PokemonCardData>[]);
    for (final card in PokemonCardData.library) {
      if (card.binderName != name) continue;
      final index = card.page - 1;
      if (index >= 0 && index < result.length) {
        result[index].add(card);
      }
    }
    return result;
  }

  int get cardCount =>
      PokemonCardData.library.where((c) => c.binderName == name).length;

  /// Builds a binder from a row returned by the `binders` table.
  factory BinderData.fromRow(Map<String, dynamic> row) {
    return BinderData(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String? ?? '',
      pageCount: (row['page_count'] as num?)?.toInt() ?? 1,
      slotsPerPage: (row['slots_per_page'] as num?)?.toInt() ?? 9,
      category: row['category'] as String? ?? kUncategorized,
      isPinned: row['is_pinned'] as bool? ?? false,
      createdAt: row['created_at'] == null
          ? null
          : DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  /// The row to upsert into the `binders` table. `user_id` is left out —
  /// the column defaults to `auth.uid()` on insert and never changes on
  /// update.
  ///
  /// Timestamps are sent as UTC. A local [DateTime]'s ISO string has no
  /// offset, which Postgres reads as UTC, so every save used to shift the
  /// stored time by the device's UTC offset. `created_at` is omitted when
  /// unknown so the column's `now()` default applies, instead of storing
  /// 1970-01-01.
  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'page_count': pageCount,
      'slots_per_page': slotsPerPage,
      'category': category,
      'is_pinned': isPinned,
      if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
    };
  }

  BinderData copyWith({
    String? name,
    String? description,
    int? pageCount,
    int? slotsPerPage,
    String? category,
    bool? isPinned,
    DateTime? createdAt,
  }) {
    return BinderData(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      pageCount: pageCount ?? this.pageCount,
      slotsPerPage: slotsPerPage ?? this.slotsPerPage,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// The signed-in user's binders — id, name, pin state, page count and
  /// the like — loaded from the `binders` table by
  /// [BinderRepository.loadAll]. Empty until then. Every screen that lists
  /// or edits binders reads and writes this same list, the same way
  /// screens share [PokemonCardData.library] and [DeckData.library].
  /// What's *inside* a binder isn't stored here at all; see [pages].
  static final List<BinderData> library = [];
}
