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