import 'package:flutter/foundation.dart';

@immutable
class TrainerProfileData {
  final String name;
  final String title;
  final String? bio;
  final String? avatarUrl;

  final String? favoriteCardId;
  final String? favoriteBinderId;
  final String? favoriteDeckId;

  const TrainerProfileData({
    required this.name,
    this.title = 'Gym Leader',
    this.bio,
    this.avatarUrl,
    this.favoriteCardId,
    this.favoriteBinderId,
    this.favoriteDeckId,
  });

  TrainerProfileData copyWith({
    String? name,
    String? title,
    Object? bio = _unset,
    Object? avatarUrl = _unset,
    Object? favoriteCardId = _unset,
    Object? favoriteBinderId = _unset,
    Object? favoriteDeckId = _unset,
  }) {
    return TrainerProfileData(
      name: name ?? this.name,
      title: title ?? this.title,
      bio: identical(bio, _unset) ? this.bio : bio as String?,
      avatarUrl: identical(avatarUrl, _unset)
          ? this.avatarUrl
          : avatarUrl as String?,
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

  factory TrainerProfileData.fromRow(Map<String, dynamic> row) {
    return TrainerProfileData(
      name: row['name'] as String,
      title: row['title'] as String? ?? 'Gym Leader',
      bio: row['bio'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      favoriteCardId: row['favorite_card_id'] as String?,
      favoriteBinderId: row['favorite_binder_id'] as String?,
      favoriteDeckId: row['favorite_deck_id'] as String?,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'name': name,
      'title': title,
      'bio': bio,
      'avatar_url': avatarUrl,
      'favorite_card_id': favoriteCardId,
      'favorite_binder_id': favoriteBinderId,
      'favorite_deck_id': favoriteDeckId,
    };
  }

  static const List<String> titleOptions = [
    'Trainer',
    'Gym Leader',
    'Elite Four',
    'Champion',
    'Pokémon Professor',
    'Collector',
  ];
}
