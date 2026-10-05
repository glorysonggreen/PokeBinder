import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/binder_data.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import '../models/trainer_profile_data.dart';
import '../services/trainer_profile_repository.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';
import '../widgets/pokemon_card_widget.dart';
import '../widgets/trainer_avatar.dart';
import 'avatar_crop_screen.dart';
import 'trainer_favorite_card_screen.dart';
import '../services/audio_service.dart';
import '../widgets/pokebinder_background.dart';
import '../widgets/pokebinder_toast.dart';

const _noneValue = '__none__';
const double _kAvatarActionWidth = 150;

class TrainerCardEditScreen extends StatefulWidget {
  final TrainerProfileData profile;

  const TrainerCardEditScreen({super.key, required this.profile});

  @override
  State<TrainerCardEditScreen> createState() => _TrainerCardEditScreenState();
}

class _TrainerCardEditScreenState extends State<TrainerCardEditScreen> {
  late final _nameController =
      TextEditingController(text: widget.profile.name);
  late final _bioController =
      TextEditingController(text: widget.profile.bio ?? '');

  late String _title = widget.profile.title;
  late String? _favoriteCardId = widget.profile.favoriteCardId;
  late String? _favoriteBinderId = widget.profile.favoriteBinderId;
  late String? _favoriteDeckId = widget.profile.favoriteDeckId;

  late String? _avatarUrl = widget.profile.avatarUrl;
  Uint8List? _newAvatarBytes;
  bool _saving = false;

  String? _nameError;

  PokemonCardData? get _selectedCard {
    if (_favoriteCardId == null) return null;
    final library = PokemonCardData.library;
    final matches = library.where((c) => c.id == _favoriteCardId);
    return matches.isNotEmpty ? matches.first : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickFavoriteCard() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => TrainerFavoriteCardScreen(
          initialCardId: _favoriteCardId,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _favoriteCardId = result.isEmpty ? null : result);
  }

  Future<void> _pickAvatar() async {
    Uint8List? bytes;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      bytes = await picked?.readAsBytes();
    } catch (_) {
      _showMessage("Couldn't open your photos.");
      return;
    }
    if (bytes == null || !mounted) return;
    final picture = bytes;

    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => AvatarCropScreen(imageBytes: picture)),
    );
    if (cropped == null || !mounted) return;
    setState(() => _newAvatarBytes = cropped);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    PokeBinderToast.show(context, message, kind: ToastKind.error);
  }

  void _removeAvatar() => setState(() {
        _newAvatarBytes = null;
        _avatarUrl = null;
      });

  Future<void> _submit() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Give your trainer a name first.');
      return;
    }

    setState(() => _saving = true);
    var avatarUrl = _avatarUrl;
    try {
      final bytes = _newAvatarBytes;
      if (bytes != null) {
        avatarUrl = await TrainerProfileRepository.uploadAvatar(bytes);
      } else if (avatarUrl == null && widget.profile.avatarUrl != null) {
        await TrainerProfileRepository.deleteAvatar();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage("Couldn't upload your photo. Please try again.");
      return;
    }
    if (!mounted) return;

    final bio = _bioController.text.trim();
    final updated = widget.profile.copyWith(
      name: name,
      title: _title,
      bio: bio.isEmpty ? null : bio,
      avatarUrl: avatarUrl,
      favoriteCardId: _favoriteCardId,
      favoriteBinderId: _favoriteBinderId,
      favoriteDeckId: _favoriteDeckId,
    );

    PokeBinderAudio.play(Sfx.save);
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final binders = BinderData.library;
    final decks = DeckData.library;

    return PokeBinderScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: PokeBinderSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackLink(onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('Edit Trainer Card', style: PokeBinderText.heading),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text(
                'Update how your trainer card introduces you.',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),

              _AvatarPicker(
                imageUrl: _avatarUrl,
                imageBytes: _newAvatarBytes,
                onPick: _pickAvatar,
                onRemove: _removeAvatar,
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),

              LabeledFormField(
                label: 'Trainer name',
                child: TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: pokeInputDecoration(
                    hint: 'e.g. Ash K.',
                    icon: Icons.person_outline,
                  ),
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                ),
              ),
              if (_nameError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp2),
                  child: Text(_nameError!, style: PokeBinderText.formError),
                ),

              LabeledFormField(
                label: 'Title',
                child: PokeDropdownField<String>(
                  value: _title,
                  icon: Icons.military_tech_outlined,
                  options: [
                    for (final option in TrainerProfileData.titleOptions)
                      PokeDropdownOption(option, option),
                    if (!TrainerProfileData.titleOptions.contains(_title))
                      PokeDropdownOption(_title, _title),
                  ],
                  onChanged: (value) => setState(() => _title = value),
                ),
              ),

              LabeledFormField(
                label: 'Favorite Card',
                child: _FavoriteCardField(
                  card: _selectedCard,
                  onTap: _pickFavoriteCard,
                ),
              ),

              LabeledFormField(
                label: 'Favorite Binder',
                child: PokeDropdownField<String>(
                  value: _favoriteBinderId ?? _noneValue,
                  icon: Icons.menu_book_outlined,
                  options: [
                    const PokeDropdownOption(_noneValue, 'No favorite'),
                    for (final binder in binders)
                      PokeDropdownOption(binder.id, binder.name),
                  ],
                  onChanged: (value) => setState(
                    () => _favoriteBinderId =
                        value == _noneValue ? null : value,
                  ),
                ),
              ),

              LabeledFormField(
                label: 'Favorite Deck',
                child: PokeDropdownField<String>(
                  value: _favoriteDeckId ?? _noneValue,
                  icon: Icons.style_outlined,
                  options: [
                    const PokeDropdownOption(_noneValue, 'No favorite'),
                    for (final deck in decks)
                      PokeDropdownOption(deck.id, deck.name),
                  ],
                  onChanged: (value) => setState(
                    () => _favoriteDeckId = value == _noneValue ? null : value,
                  ),
                ),
              ),

              LabeledFormField(
                label: 'Bio (optional)',
                child: TextField(
                  controller: _bioController,
                  keyboardType: TextInputType.multiline,
                  minLines: 3,
                  maxLines: 5,
                  decoration: pokeInputDecoration(
                    hint: 'A line about your collection or trainer journey',
                  ),
                ),
              ),

              const SizedBox(height: PokeBinderSpacing.sp2),
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: 'Cancel',
                      ghost: true,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const SizedBox(width: PokeBinderSpacing.sp2),
                  Expanded(
                    child: PillButton(
                      label: _saving ? 'Saving…' : 'Save Changes',
                      icon: Icons.check,
                      enabled: !_saving,
                      onTap: _submit,
                    ),
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

class _FavoriteCardField extends StatelessWidget {
  final PokemonCardData? card;
  final VoidCallback onTap;

  const _FavoriteCardField({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = card;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: PokeBinderSpacing.sp3,
            vertical: PokeBinderSpacing.sp3,
          ),
          decoration: BoxDecoration(
            color: PokeBinderColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              if (selected != null) ...[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: kCardElevation,
                  ),
                  child: CardThumbnail(
                    card: selected,
                    width: 30,
                    height: 42,
                    borderRadius: 6,
                  ),
                ),
                const SizedBox(width: PokeBinderSpacing.sp2),
              ] else ...[
                Icon(
                  Icons.star_outline_rounded,
                  size: 16,
                  color: PokeBinderColors.redDeep.withValues(alpha: 0.55),
                ),
                const SizedBox(width: PokeBinderSpacing.sp2),
              ],
              Expanded(
                child: Text(
                  selected != null ? selected.name : 'Choose a favorite card',
                  overflow: TextOverflow.ellipsis,
                  style: PokeBinderText.selectValue,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: PokeBinderColors.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _AvatarPicker({
    required this.imageUrl,
    required this.imageBytes,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = imageUrl != null || imageBytes != null;

    return Center(
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPick,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  TrainerAvatar(
                    imageUrl: imageUrl,
                    imageBytes: imageBytes,
                    size: 96,
                    iconSize: 40,
                    borderWidth: 3,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: PokeBinderColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: PokeBinderColors.ink.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Icon(
                        Icons.photo_camera_rounded,
                        size: 16,
                        color: PokeBinderColors.redDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: PokeBinderSpacing.sp3),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: _kAvatarActionWidth,
                child: PillButton(
                  label: hasPhoto ? 'Change Photo' : 'Upload Photo',
                  icon: hasPhoto ? Icons.edit_rounded : Icons.upload_rounded,
                  ghost: true,
                  onTap: onPick,
                ),
              ),
              if (hasPhoto) ...[
                const SizedBox(height: PokeBinderSpacing.sp3),
                DangerActionButton(label: 'Remove', onTap: onRemove),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
