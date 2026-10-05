import 'package:flutter/foundation.dart';
import 'pokemon_card_data.dart';

const kUnassignedBinderId = '__unassigned__';

const kUnassignedBinderName = 'Unassigned';
const kUncategorized = '';

@immutable
class BinderData {
  final String id;
  final String name;
  final String description;

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

  double get totalValue => PokemonCardData.library
      .where((c) => c.binderName == name)
      .fold(0.0, (sum, c) => sum + c.estimatedValue);

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

  static final List<BinderData> library = [];
}
