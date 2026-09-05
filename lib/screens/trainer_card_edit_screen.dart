import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import '../models/trainer_profile_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';
import '../widgets/pokemon_card_widget.dart';
import 'trainer_favorite_card_screen.dart';

/// Sentinel dropdown value meaning "no favorite chosen" — kept as a plain
/// string so the binder/deck pickers can reuse [PokeDropdownField]'s
/// non-nullable generic the same way every other dropdown in the app does.
const _noneValue = '__none__';

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
    final result = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => TrainerFavoriteCardScreen(
          initialCardId: _favoriteCardId,
        ),
      ),
    );
    if (!mounted) return;
    // A null pop from the back button leaves the current choice alone; only
    // an explicit "Done"/"Clear" result (still nullable) updates it.
    setState(() => _favoriteCardId = result);
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Give your trainer a name first.');
      return;
    }

    final bio = _bioController.text.trim();
    final updated = widget.profile.copyWith(
      name: name,
      title: _title,
      bio: bio.isEmpty ? null : bio,
      favoriteCardId: _favoriteCardId,
      favoriteBinderId: _favoriteBinderId,
      favoriteDeckId: _favoriteDeckId,
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final binders = BinderData.sampleBinders;
    final decks = DeckData.sampleDecks;

    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            PokeBinderSpacing.sp4,
            PokeBinderSpacing.sp4,
            PokeBinderSpacing.sp4,
            PokeBinderSpacing.sp6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackLink(onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('Edit Trainer Card', style: PokeBinderText.heading),
              const SizedBox(height: 4),
              Text(
                'Update how your trainer card introduces you.',
                style: PokeBinderText.subtitle,
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
                      label: 'Save Changes',
                      icon: Icons.check,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                const SizedBox(width: 10),
              ] else ...[
                Icon(
                  Icons.star_outline_rounded,
                  size: 16,
                  color: PokeBinderColors.redDeep.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  selected != null ? selected.name : 'Choose a favorite card',
                  overflow: TextOverflow.ellipsis,
                  style: PokeBinderText.fieldValue
                      .copyWith(fontSize: 13, fontWeight: FontWeight.w600),
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