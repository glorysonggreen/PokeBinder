import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';

const _kRarityOptions = [
  'Common',
  'Uncommon',
  'Rare',
  'Double Rare',
  'Illustration Rare',
  'Special Illustration Rare',
  'Hyper Rare',
  'Promo',
  'Other/Additional Rarities',
];

const _kConditionOptions = [
  ('Near Mint', 'NM'),
  ('Lightly Played', 'LP'),
  ('Moderately Played', 'MP'),
  ('Damaged', 'DMG'),
];

class CardFormResult {
  final PokemonCardData? card;
  final String? binderId;
  final int? pageIndex;
  final bool deleted;

  const CardFormResult.saved({
    required PokemonCardData card,
    required String binderId,
    required int pageIndex,
  })  : card = card,
        binderId = binderId,
        pageIndex = pageIndex,
        deleted = false;

  const CardFormResult.deleted()
      : card = null,
        binderId = null,
        pageIndex = null,
        deleted = true;
}

class CardFormScreen extends StatefulWidget {
  final PokemonCardData? existingCard;
  final List<BinderData> binders;
  final String defaultBinderId;
  final int defaultPageNumber;

  const CardFormScreen({
    super.key,
    this.existingCard,
    required this.binders,
    required this.defaultBinderId,
    this.defaultPageNumber = 1,
  });

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  late final _nameController =
      TextEditingController(text: widget.existingCard?.name ?? '');
  late final _setController =
      TextEditingController(text: widget.existingCard?.setName ?? '');
  late final _cardNumberController =
      TextEditingController(text: widget.existingCard?.cardNumber ?? '');
  late final _quantityController = TextEditingController(
    text: '${widget.existingCard?.quantityOwned ?? 1}',
  );
  late final _valueController = TextEditingController(
    text: widget.existingCard != null
        ? widget.existingCard!.estimatedValue.toStringAsFixed(0)
        : '',
  );
  late final _pageController =
      TextEditingController(text: '${widget.defaultPageNumber}');
  late final _notesController =
      TextEditingController(text: widget.existingCard?.notes ?? '');

  late String _rarity = widget.existingCard?.rarity ?? _kRarityOptions.first;
  late String _conditionCode = _kConditionOptions.firstWhere(
    (option) => option.$2 == widget.existingCard?.condition,
    orElse: () => _kConditionOptions.first,
  ).$2;
  late String _binderId = widget.existingCard == null
      ? widget.defaultBinderId
      : widget.binders
          .firstWhere(
            (b) => b.name == widget.existingCard!.binderName,
            orElse: () => const BinderData(
              id: kUnassignedBinderId,
              name: 'Unassigned',
              pages: [],
            ),
          )
          .id;

  String? _nameError;
  String? _quantityError;

  bool get _isEditing => widget.existingCard != null;

  @override
  void dispose() {
    _nameController.dispose();
    _setController.dispose();
    _cardNumberController.dispose();
    _quantityController.dispose();
    _valueController.dispose();
    _pageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Give the card a name first.');
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity < 1) {
      setState(() => _quantityError = 'Quantity must be at least 1.');
      return;
    }

    final unassigned = _binderId == kUnassignedBinderId;
    final binder = unassigned
        ? null
        : widget.binders.firstWhere((b) => b.id == _binderId,
            orElse: () => widget.binders.first);
    final value = double.tryParse(_valueController.text) ?? 0;
    final page = int.tryParse(_pageController.text) ?? widget.defaultPageNumber;
    final pageNumber = unassigned ? 0 : (page < 1 ? 1 : page);

    final card = PokemonCardData(
      id: widget.existingCard?.id ?? 'card-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      setName: _setController.text.trim(),
      cardNumber: _cardNumberController.text.trim(),
      rarity: _rarity,
      type: widget.existingCard?.type ?? PokemonCardType.colorless,
      quantityOwned: quantity,
      condition: _conditionCode,
      binderName: binder?.name ?? 'Unassigned',
      page: pageNumber,
      estimatedValue: value < 0 ? 0 : value,
      notes: _notesController.text.trim(),
      imageAssetPath: widget.existingCard?.imageAssetPath,
      dateAdded: widget.existingCard?.dateAdded ?? DateTime.now(),
    );

    Navigator.of(context).pop(
      CardFormResult.saved(
        card: card,
        binderId: binder?.id ?? kUnassignedBinderId,
        pageIndex: pageNumber - 1 < 0 ? 0 : pageNumber - 1,
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final card = widget.existingCard!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete card?'),
        content: Text(
          'This removes "${card.name}" from your collection. '
          "This can't be undone.",
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
              'Delete',
              style: TextStyle(color: PokeBinderColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop(const CardFormResult.deleted());
    }
  }

  @override
  Widget build(BuildContext context) {
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
              BackLink(
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text(
                _isEditing ? 'Edit Card' : 'Add a Card',
                style: PokeBinderText.heading,
              ),
              const SizedBox(height: 4),
              Text(
                _isEditing
                    ? 'Update the details below.'
                    : 'No scanner handy? Enter the details yourself.',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),

              LabeledFormField(
                label: 'Card name',
                child: TextField(
                  controller: _nameController,
                  decoration: pokeInputDecoration(
                    hint: 'e.g. Charizard',
                    icon: Icons.badge_outlined,
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

              FormFieldRow(
                left: LabeledFormField(
                  label: 'Set',
                  child: TextField(
                    controller: _setController,
                    decoration: pokeInputDecoration(
                      hint: 'Base Set',
                      icon: Icons.collections_bookmark_outlined,
                    ),
                  ),
                ),
                right: LabeledFormField(
                  label: 'Card number',
                  child: TextField(
                    controller: _cardNumberController,
                    decoration: pokeInputDecoration(
                      hint: '4/102',
                      icon: Icons.tag_rounded,
                    ),
                  ),
                ),
              ),

              FormFieldRow(
                left: LabeledFormField(
                  label: 'Rarity',
                  child: PokeDropdownField<String>(
                    value: _rarity,
                    icon: Icons.diamond_rounded,
                    options: [
                      for (final r in _kRarityOptions)
                        PokeDropdownOption(r, r, icon: rarityIconFor(r)),
                    ],
                    onChanged: (value) => setState(() => _rarity = value),
                  ),
                ),
                right: LabeledFormField(
                  label: 'Condition',
                  child: PokeDropdownField<String>(
                    value: _conditionCode,
                    icon: Icons.health_and_safety_outlined,
                    options: [
                      for (final c in _kConditionOptions)
                        PokeDropdownOption(c.$2, c.$1,
                            icon: conditionIconFor(c.$2)),
                    ],
                    onChanged: (value) => setState(() => _conditionCode = value),
                  ),
                ),
              ),

              FormFieldRow(
                left: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabeledFormField(
                      label: 'Quantity',
                      child: TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: pokeInputDecoration(icon: Icons.style_outlined),
                        onChanged: (_) {
                          if (_quantityError != null) {
                            setState(() => _quantityError = null);
                          }
                        },
                      ),
                    ),
                    if (_quantityError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp2),
                        child:
                            Text(_quantityError!, style: PokeBinderText.formError),
                      ),
                  ],
                ),
                right: LabeledFormField(
                  label: 'Est. value (₱)',
                  child: TextField(
                    controller: _valueController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: pokeInputDecoration(
                      hint: '0.00',
                      icon: Icons.payments_outlined,
                    ),
                  ),
                ),
              ),

              FormFieldRow(
                left: LabeledFormField(
                  label: 'Binder',
                  child: PokeDropdownField<String>(
                    value: _binderId,
                    icon: Icons.menu_book_outlined,
                    options: [
                      for (final b in widget.binders)
                        PokeDropdownOption(b.id, b.name),
                      const PokeDropdownOption(
                          kUnassignedBinderId, 'No binder (unassigned)'),
                    ],
                    onChanged: (value) => setState(() => _binderId = value),
                  ),
                ),
                right: LabeledFormField(
                  label: 'Page',
                  child: TextField(
                    controller: _pageController,
                    enabled: _binderId != kUnassignedBinderId,
                    keyboardType: TextInputType.number,
                    decoration: pokeInputDecoration(
                      hint: _binderId == kUnassignedBinderId ? '—' : '4',
                      icon: Icons.bookmark_outline_rounded,
                    ),
                  ),
                ),
              ),

              LabeledFormField(
                label: 'Notes (optional)',
                child: TextField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 8,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: pokeInputDecoration(
                    hint: 'Condition details, top loader, etc.',
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
                      label: _isEditing ? 'Save Changes' : 'Add to Binder',
                      icon: _isEditing ? Icons.check : Icons.add,
                      onTap: _submit,
                    ),
                  ),
                ],
              ),

              if (_isEditing) ...[
                const SizedBox(height: PokeBinderSpacing.sp4),
                Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _confirmDelete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: PokeBinderSpacing.sp3,
                          vertical: PokeBinderSpacing.sp2,
                        ),
                        decoration: BoxDecoration(
                          color: PokeBinderColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 14,
                              color: PokeBinderColors.danger,
                            ),
                            SizedBox(width: PokeBinderSpacing.sp2),
                            Text(
                              'Delete Card',
                              style: TextStyle(
                                color: PokeBinderColors.danger,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}