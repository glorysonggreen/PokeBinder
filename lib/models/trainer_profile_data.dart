import 'package:flutter/foundation.dart';

@immutable
class TrainerProfileData {
  final String name;
  final String title;
  final String? bio;

  /// IDs of the trainer's chosen favorites, picked explicitly through the
  /// trainer card editor (rather than inferred from "pinned" or "most
  /// recent"). Null means nothing has been chosen yet.
  final String? favoriteCardId;
  final String? favoriteBinderId;
  final String? favoriteDeckId;

  const TrainerProfileData({
    required this.name,
    this.title = 'Gym Leader',
    this.bio,
    this.favoriteCardId,
    this.favoriteBinderId,
    this.favoriteDeckId,
  });

  TrainerProfileData copyWith({
    String? name,
    String? title,
    Object? bio = _unset,
    Object? favoriteCardId = _unset,
    Object? favoriteBinderId = _unset,
    Object? favoriteDeckId = _unset,
  }) {
    return TrainerProfileData(
      name: name ?? this.name,
      title: title ?? this.title,
      bio: identical(bio, _unset) ? this.bio : bio as String?,
      favoriteCardId: identical(favoriteCardId, _unset)
          ? this.favoriteCardId
          : favoriteCardId as String?,
      favoriteBinderId: identical(favoriteBinderId, _unset)
          ? this.favoriteBinderId
          : favoriteBinderId as String?,
      favoriteDeckId: identical(favoriteDeckId, _unset)
          ? this.favoriteDeckId
          : favoriteDeckId as String?,
    );
  }

  static const _unset = Object();

  /// Builds a profile from a row returned by the `trainer_profiles` table.
  factory TrainerProfileData.fromRow(Map<String, dynamic> row) {
    return TrainerProfileData(
      name: row['name'] as String,
      title: row['title'] as String? ?? 'Gym Leader',
      bio: row['bio'] as String?,
      favoriteCardId: row['favorite_card_id'] as String?,
      favoriteBinderId: row['favorite_binder_id'] as String?,
      favoriteDeckId: row['favorite_deck_id'] as String?,
    );
  }

  /// The row to upsert into the `trainer_profiles` table. `user_id` is
  /// left out — it's the table's primary key and defaults to `auth.uid()`
  /// on insert, and never changes on update.
  Map<String, dynamic> toRow() {
    return {
      'name': name,
      'title': title,
      'bio': bio,
      'favorite_card_id': favoriteCardId,
      'favorite_binder_id': favoriteBinderId,
      'favorite_deck_id': favoriteDeckId,
    };
  }

  /// Preset titles offered in the trainer card editor. Not exhaustive —
  /// the field itself is a picker over this list, matching the app's
  /// existing dropdown pattern for short, structured fields.
  static const List<String> titleOptions = [
    'Trainer',
    'Gym Leader',
    'Elite Four',
    'Champion',
    'Pokémon Professor',
    'Collector',
  ];
}