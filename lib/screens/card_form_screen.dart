import 'package:flutter/material.dart';
import '../config/pricing.dart';
import '../models/binder_data.dart';
import '../models/catalog_card.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/card_viewer.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';
import '../widgets/pokemon_card_widget.dart';

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
  /// A card picked from the catalog. Its name, set, number, rarity, type and
  /// artwork are filled in and locked; only the person's own copy details
  /// (condition, quantity, value, binder, page, notes) can be changed.
  final CatalogCard? catalogCard;
  final List<BinderData> binders;
  final String defaultBinderId;
  final int defaultPageNumber;

  const CardFormScreen({
    super.key,
    this.existingCard,
    this.catalogCard,
    required this.binders,
    required this.defaultBinderId,
    this.defaultPageNumber = 1,
  });

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  // What the person chose on the last card they added, kept for the rest of
  // the session so adding a run of cards to one binder takes fewer taps.
  static String? _lastBinderId;
  static int? _lastPage;
  static String? _lastCondition;

  /// The catalog row this card is (or will be) linked to, if any.
  String? get _catalogId => widget.existingCard?.catalogId ?? widget.catalogCard?.id;

  /// True when the card's identity comes from the catalog, so it is shown as
  /// read-only text instead of editable fields. That is what keeps the name,
  /// set, number, rarity and artwork correct.
  bool get _isLocked => _catalogId != null;

  late final _nameController = TextEditingController(
      text: widget.existingCard?.name ?? widget.catalogCard?.name ?? '');
  late final _setController = TextEditingController(
      text: widget.existingCard?.setName ?? widget.catalogCard?.setName ?? '');
  late final _cardNumberController = TextEditingController(
      text: widget.existingCard?.cardNumber ??
          widget.catalogCard?.displayNumber ??
          '');
  late final _quantityController = TextEditingController(
    text: '${widget.existingCard?.quantityOwned ?? 1}',
  );
  late final _valueController = TextEditingController(
    text: widget.existingCard != null
        ? widget.existingCard!.estimatedValue.toStringAsFixed(0)
        : _suggestedValue?.toStringAsFixed(0) ?? '',
  );
  late final _pageController = TextEditingController(
    text: _restoredPlacement
        ? '${_lastPage ?? widget.defaultPageNumber}'
        : '${widget.defaultPageNumber}',
  );
  // Shown (empty) in place of the page number while no binder is chosen, so a
  // stale "1" doesn't sit greyed-out in the field.
  final _noPageController = TextEditingController();
  late final _notesController =
      TextEditingController(text: widget.existingCard?.notes ?? '');

  late String _rarity = widget.existingCard?.rarity ??
      widget.catalogCard?.rarity ??
      kRarityOptions.first;
  late CardSupertype _supertype = widget.existingCard?.supertype ??
      widget.catalogCard?.supertype ??
      CardSupertype.pokemon;
  late PokemonCardType _type = widget.existingCard?.type ??
      widget.catalogCard?.type ??
      PokemonCardType.colorless;
  late String? _subtype =
      widget.existingCard?.subtype ?? widget.catalogCard?.subtype;
  late String _conditionCode = kConditionOptions.firstWhere(
    (option) => option.$2 == (widget.existingCard?.condition ?? _lastCondition),
    orElse: () => kConditionOptions.first,
  ).$2;

  /// The printing (holofoil, reverse holo ...) of the copy.
  late String? _finish =
      widget.existingCard?.finish ?? widget.catalogCard?.defaultFinish;

  /// A new card opened without a binder goes where the last one went.
  late final bool _restoredPlacement = !_isEditing &&
      widget.defaultBinderId == kUnassignedBinderId &&
      _lastBinderId != null &&
      widget.binders.any((b) => b.id == _lastBinderId);

  late String _binderId = _restoredPlacement
      ? _lastBinderId!
      : widget.existingCard == null
      ? widget.defaultBinderId
      : widget.binders
          .firstWhere(
            (b) => b.name == widget.existingCard!.binderName,
            orElse: () => const BinderData(
              id: kUnassignedBinderId,
              name: kUnassignedBinderName,
              pageCount: 0,
            ),
          )
          .id;

  String? _nameError;
  String? _quantityError;

  /// True once the person has typed a value that differs from the automatic
  /// price. From then on, changing the condition leaves their value alone.
  bool _valueEdited = false;

  bool get _isEditing => widget.existingCard != null;

  /// Subtype choices the manual form offers for each supertype. They match
  /// the values the collection's filter chips look for.
  static const _trainerSubtypes = ['Item', 'Supporter', 'Stadium'];
  static const _energySubtypes = ['Basic', 'Special'];

  List<String> get _subtypeChoices => switch (_supertype) {
        CardSupertype.trainer => _trainerSubtypes,
        CardSupertype.energy => _energySubtypes,
        CardSupertype.pokemon => const [],
      };

  String get _title => _isEditing
      ? 'Edit Card'
      : _isLocked
          ? 'Add to Collection'
          : 'Add a Card Manually';

  String get _subtitle => _isEditing
      ? 'Update the details below.'
      : _isLocked
          ? 'Confirm the details of your copy.'
          : "Can't find it in the card database? Enter the details yourself.";

  @override
  void dispose() {
    _nameController.dispose();
    _setController.dispose();
    _cardNumberController.dispose();
    _quantityController.dispose();
    _valueController.dispose();
    _pageController.dispose();
    _noPageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (!_isLocked && name.isEmpty) {
      setState(() => _nameError = 'Give the card a name first.');
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity < 1) {
      setState(() => _quantityError = 'Quantity must be at least 1.');
      return;
    }

    // A page the binder doesn't have: the note under the field says why.
    final pageStatus = _pageStatus;
    if (pageStatus != null && pageStatus.error) {
      setState(() {});
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

    // A linked card keeps the catalog's type and subtype untouched. A manual
    // card gets the ones picked in the form; trainers have no energy type,
    // and the subtype must be one the chosen kind actually offers.
    final type = !_isLocked && _supertype == CardSupertype.trainer
        ? PokemonCardType.colorless
        : _type;
    String? subtype = _subtype;
    if (!_isLocked) {
      final choices = _subtypeChoices;
      subtype = choices.isEmpty
          ? null
          : (choices.contains(subtype) ? subtype : choices.first);
    }

    final card = PokemonCardData(
      id: widget.existingCard?.id ?? 'card-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      setName: _setController.text.trim(),
      cardNumber: _cardNumberController.text.trim(),
      rarity: _rarity,
      type: type,
      supertype: _supertype,
      subtype: subtype,
      quantityOwned: quantity,
      condition: _conditionCode,
      binderName: binder?.name ?? kUnassignedBinderName,
      page: pageNumber,
      estimatedValue: value < 0 ? 0 : value,
      notes: _notesController.text.trim(),
      imageAssetPath:
          widget.existingCard?.imageAssetPath ?? widget.catalogCard?.collectionImage,
      catalogId: _catalogId,
      finish: _finish,
      dateAdded: widget.existingCard?.dateAdded ?? DateTime.now(),
    );

    if (!_isEditing) {
      _rememberChoices(
        binderId: binder?.id ?? kUnassignedBinderId,
        page: pageNumber,
      );
    }

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

  static String _typeLabel(PokemonCardType t) =>
      t.name[0].toUpperCase() + t.name.substring(1);

  Widget _typeDropdown() => LabeledFormField(
        label: 'Type',
        child: PokeDropdownField<PokemonCardType>(
          value: _type,
          icon: Icons.bolt_rounded,
          options: [
            for (final t in PokemonCardType.values)
              PokeDropdownOption(t, _typeLabel(t), icon: t.typeIcon),
          ],
          onChanged: (value) => setState(() => _type = value),
        ),
      );

  Widget _subtypeDropdown() => LabeledFormField(
        label: 'Subtype',
        child: PokeDropdownField<String>(
          value: _subtypeChoices.contains(_subtype)
              ? _subtype!
              : _subtypeChoices.first,
          icon: Icons.label_outline_rounded,
          options: [
            for (final o in _subtypeChoices) PokeDropdownOption(o, o),
          ],
          onChanged: (value) => setState(() => _subtype = value),
        ),
      );

  /// The identity fields for a card that is not in the catalog. For a
  /// catalog card these are replaced by the read-only [_CatalogSummary].
  List<Widget> _manualIdentityFields() {
    return [
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
          label: 'Card kind',
          child: PokeDropdownField<CardSupertype>(
            value: _supertype,
            icon: Icons.category_outlined,
            options: const [
              PokeDropdownOption(CardSupertype.pokemon, 'Pokémon'),
              PokeDropdownOption(CardSupertype.trainer, 'Trainer'),
              PokeDropdownOption(CardSupertype.energy, 'Energy'),
            ],
            onChanged: (value) => setState(() {
              _supertype = value;
              _subtype = null;
            }),
          ),
        ),
        right: LabeledFormField(
          label: 'Rarity',
          child: PokeDropdownField<String>(
            value: kRarityOptions.contains(_rarity)
                ? _rarity
                : kRarityOptions.first,
            icon: Icons.diamond_rounded,
            options: [
              for (final r in kRarityOptions)
                PokeDropdownOption(r, r, icon: rarityIconFor(r)),
            ],
            onChanged: (value) => setState(() => _rarity = value),
          ),
        ),
      ),
      if (_supertype == CardSupertype.trainer)
        _subtypeDropdown()
      else if (_supertype == CardSupertype.energy)
        FormFieldRow(left: _typeDropdown(), right: _subtypeDropdown())
      else
        _typeDropdown(),
    ];
  }

  /// Near Mint market price in US dollars for the chosen printing.
  double? get _marketUsd => widget.catalogCard?.priceUsdFor(_finish);

  double? get _marketPhp {
    final usd = _marketUsd;
    return usd == null ? null : roundPeso(usd * kUsdToPhpRate);
  }

  /// The peso value suggested for this copy: the Near Mint price of the chosen
  /// printing, scaled for the chosen condition. Null when there is no catalog
  /// price.
  double? get _suggestedValue {
    final nearMint = _isEditing ? null : _marketPhp;
    return nearMint == null ? null : priceForCondition(nearMint, _conditionCode);
  }

  /// Re-fills the value after the condition or finish changes, unless the
  /// person has typed their own number.
  void _refreshSuggestedValue() {
    final suggested = _suggestedValue;
    if (!_valueEdited && suggested != null) {
      _valueController.text = suggested.toStringAsFixed(0);
    }
  }

  void _setCondition(String code) {
    setState(() {
      _conditionCode = code;
      _refreshSuggestedValue();
    });
  }

  void _setFinish(String finish) {
    setState(() {
      _finish = finish;
      _refreshSuggestedValue();
    });
  }

  /// The printings this card has prices for. The picker only appears when
  /// there is a real choice.
  List<String> get _finishes => widget.catalogCard?.finishes ?? const [];

  // ---- Binder page ----------------------------------------------------------

  BinderData? get _selectedBinder {
    if (_binderId == kUnassignedBinderId) return null;
    for (final b in widget.binders) {
      if (b.id == _binderId) return b;
    }
    return null;
  }

  /// A note about the chosen page: how full it is, that it would add a page,
  /// or (an error that blocks saving) that the binder doesn't have that page.
  ({String text, bool error})? get _pageStatus {
    final binder = _selectedBinder;
    if (binder == null) return null;
    final raw = _pageController.text.trim();
    if (raw.isEmpty) return null;

    final count = binder.pageCount;
    final page = int.tryParse(raw);
    if (page == null || page < 1) {
      return (text: 'Enter a page number from 1 to $count.', error: true);
    }
    if (page > count + 1) {
      return (
        text: '${binder.name} has $count page${count == 1 ? '' : 's'}. '
            'Pick 1 to $count, or ${count + 1} to add a new page.',
        error: true,
      );
    }
    if (page == count + 1) {
      return (text: 'This adds page $page to ${binder.name}.', error: false);
    }
    final used = PokemonCardData.library
        .where((c) =>
            c.binderName == binder.name &&
            c.page == page &&
            c.id != widget.existingCard?.id)
        .length;
    if (used >= binder.slotsPerPage) {
      return (
        text: 'Page $page is full ($used of ${binder.slotsPerPage} slots).',
        error: false,
      );
    }
    return (
      text: 'Page $page has $used of ${binder.slotsPerPage} slots used.',
      error: false,
    );
  }

  void _rememberChoices({required String binderId, required int page}) {
    _lastCondition = _conditionCode;
    _lastBinderId = binderId == kUnassignedBinderId ? null : binderId;
    _lastPage = page;
  }

  void _setQuantity(int value) {
    setState(() {
      _quantityController.text = '$value';
      _quantityError = null;
    });
  }

  /// Copies of this catalog card already in the collection. Only a card being
  /// newly added from the catalog can be a duplicate.
  List<PokemonCardData> get _ownedCopies {
    final id = widget.catalogCard?.id;
    if (_isEditing || id == null) return const [];
    int rank(PokemonCardData c) =>
        kConditionOptions.indexWhere((o) => o.$2 == c.condition);
    return PokemonCardData.library
        .where((c) => c.catalogId == id && c.quantityOwned > 0)
        .toList()
      ..sort((a, b) => rank(a).compareTo(rank(b)));
  }

  /// Adds the chosen quantity to an entry the person already has, instead of
  /// creating a second entry. Everything else on that entry stays as it is.
  void _addToExisting(PokemonCardData existing) {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final binderIndex =
        widget.binders.indexWhere((b) => b.name == existing.binderName);
    _rememberChoices(
      binderId: binderIndex == -1
          ? kUnassignedBinderId
          : widget.binders[binderIndex].id,
      page: existing.page,
    );
    Navigator.of(context).pop(
      CardFormResult.saved(
        card: existing.copyWith(
            quantityOwned: existing.quantityOwned + quantity),
        binderId: binderIndex == -1
            ? kUnassignedBinderId
            : widget.binders[binderIndex].id,
        pageIndex: existing.page < 1 ? 0 : existing.page - 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unassigned = _binderId == kUnassignedBinderId;
    final suggested = _suggestedValue;
    final valueDiffers = suggested != null &&
        _valueController.text.trim() != suggested.toStringAsFixed(0);
    final owned = _ownedCopies;
    final pageStatus = _pageStatus;

    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: PokeBinderSpacing.page,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BackLink(onTap: () => Navigator.of(context).maybePop()),
                    const SizedBox(height: PokeBinderSpacing.sp2),
                    Text(_title, style: PokeBinderText.heading),
                    const SizedBox(height: PokeBinderSpacing.sp1),
                    Text(_subtitle, style: PokeBinderText.subtitle),
                    const SizedBox(height: PokeBinderSpacing.sp4),

                    if (_isLocked)
                      _CatalogSummary(
                        name: _nameController.text,
                        setName: _setController.text,
                        number: _cardNumberController.text,
                        rarity: _rarity,
                        type: _type,
                        supertype: _supertype,
                        subtype: _subtype,
                        imagePath: widget.existingCard?.imageAssetPath ??
                            widget.catalogCard?.collectionImage,
                        // Only a freshly picked catalog card has a market
                        // price to show; an owned copy has its own value.
                        showPrice: !_isEditing && widget.catalogCard != null,
                        priceUsd: _marketUsd,
                        pricePhp: _marketPhp,
                        priceUpdatedAt: widget.catalogCard?.priceUpdatedAt,
                        priceCaption: _finishes.length > 1 && _finish != null
                            ? finishLabel(_finish!)
                            : null,
                        // An owned copy shows its printing as a chip; a card
                        // being added picks it below instead.
                        finishChip: _isEditing && _finish != null
                            ? finishLabel(_finish!)
                            : null,
                      )
                    else ...[
                      const _SectionTitle(
                        icon: Icons.badge_outlined,
                        label: 'Card details',
                      ),
                      ..._manualIdentityFields(),
                    ],

                    const _SectionTitle(
                      icon: Icons.style_outlined,
                      label: 'Your copy',
                    ),
                    if (_finishes.length > 1) ...[
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: PokeBinderSpacing.sp2),
                        child: Text('FINISH', style: PokeBinderText.formLabel),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: PokeBinderSpacing.sp3),
                        child: Wrap(
                          spacing: PokeBinderSpacing.sp2,
                          runSpacing: PokeBinderSpacing.sp2,
                          children: [
                            for (final finish in _finishes)
                              _FinishChip(
                                label: finishLabel(finish),
                                price: formatPeso(roundPeso(widget.catalogCard!.finishPrices[finish]! * kUsdToPhpRate)),
                                selected: finish == _finish,
                                onTap: () => _setFinish(finish),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (owned.isNotEmpty)
                      _OwnedNote(
                        copies: owned,
                        selectedCondition: _conditionCode,
                        selectedFinish: _finish,
                        defaultFinish: widget.catalogCard?.defaultFinish,
                        addQuantity: int.tryParse(_quantityController.text) ?? 1,
                        onAdd: _addToExisting,
                      ),
                    FormFieldRow(
                      left: LabeledFormField(
                        label: 'Condition',
                        child: PokeDropdownField<String>(
                          height: _kPairedFieldHeight,
                          value: _conditionCode,
                          icon: Icons.health_and_safety_outlined,
                          options: [
                            for (final c in kConditionOptions)
                              PokeDropdownOption(c.$2, c.$1,
                                  icon: conditionIconFor(c.$2)),
                          ],
                          onChanged: _setCondition,
                        ),
                      ),
                      right: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LabeledFormField(
                            label: 'Quantity',
                            child: _QuantityStepper(
                              value: int.tryParse(_quantityController.text) ?? 1,
                              onChanged: _setQuantity,
                            ),
                          ),
                          if (_quantityError != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: PokeBinderSpacing.sp2),
                              child: Text(_quantityError!,
                                  style: PokeBinderText.formError),
                            ),
                        ],
                      ),
                    ),

                    LabeledFormField(
                      label: 'Estimated value',
                      child: TextField(
                        controller: _valueController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: PokeBinderText.input,
                        // Typing counts as an override only if it differs from
                        // the automatic price; typing it back re-enables auto.
                        onChanged: (text) => setState(() => _valueEdited =
                            text.trim() != _suggestedValue?.toStringAsFixed(0)),
                        decoration: pokeInputDecoration(
                          hint: '0',
                          icon: Icons.payments_outlined,
                        ).copyWith(
                          prefixText: '₱ ',
                          prefixStyle: PokeBinderText.selectValue,
                        ),
                      ),
                    ),
                    if (suggested != null)
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: PokeBinderSpacing.sp3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _valueEdited
                                    ? 'Using your own value.'
                                    : 'Adjusts with the condition. Type your '
                                        'own value to override it.',
                                style: PokeBinderText.listRowSubtitle,
                              ),
                            ),
                            if (valueDiffers) ...[
                              const SizedBox(width: PokeBinderSpacing.sp2),
                              _MiniAction(
                                label: 'Use ${formatPeso(suggested)}',
                                icon: Icons.refresh_rounded,
                                onTap: () => setState(() {
                                  _valueController.text =
                                      suggested.toStringAsFixed(0);
                                  _valueEdited = false;
                                }),
                              ),
                            ],
                          ],
                        ),
                      ),

                    const _SectionTitle(
                      icon: Icons.menu_book_outlined,
                      label: 'Where it lives',
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: LabeledFormField(
                            label: 'Binder',
                            child: PokeDropdownField<String>(
                              value: _binderId,
                              icon: Icons.menu_book_outlined,
                              options: [
                                for (final b in widget.binders)
                                  PokeDropdownOption(b.id, b.name),
                                const PokeDropdownOption(
                                    kUnassignedBinderId, 'No binder'),
                              ],
                              onChanged: (value) =>
                                  setState(() => _binderId = value),
                            ),
                          ),
                        ),
                        const SizedBox(width: PokeBinderSpacing.sp2),
                        Expanded(
                          flex: 3,
                          child: LabeledFormField(
                            label: 'Page',
                            child: Opacity(
                              opacity: unassigned ? 0.5 : 1,
                              child: TextField(
                                controller: unassigned
                                    ? _noPageController
                                    : _pageController,
                                enabled: !unassigned,
                                keyboardType: TextInputType.number,
                                style: PokeBinderText.input,
                                onChanged: (_) => setState(() {}),
                                decoration: pokeInputDecoration(
                                  hint: unassigned ? '—' : '1',
                                  icon: Icons.bookmark_outline_rounded,
                                ).copyWith(
                                  suffixText: _selectedBinder == null
                                      ? null
                                      : 'of ${_selectedBinder!.pageCount}',
                                  suffixStyle: PokeBinderText.listRowSubtitle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (pageStatus != null)
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: PokeBinderSpacing.sp3),
                        child: Text(
                          pageStatus.text,
                          style: pageStatus.error
                              ? PokeBinderText.formError
                              : PokeBinderText.listRowSubtitle,
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
                        style: PokeBinderText.input,
                        decoration: pokeInputDecoration(
                          hint: 'Condition details, top loader, etc.',
                        ),
                      ),
                    ),

                    if (_isEditing) ...[
                      const SizedBox(height: PokeBinderSpacing.sp2),
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
                                color: PokeBinderColors.danger
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const PokeDangerLabel('Delete Card'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // The buttons stay put while the form scrolls, so "Add Card" is
            // always in reach instead of at the very bottom of a long page.
            Container(
              decoration: BoxDecoration(
                color: PokeBinderColors.cream,
                border: Border(
                  top: BorderSide(
                    color: PokeBinderColors.ink.withValues(alpha: 0.08),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: PokeBinderColors.ink.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PokeBinderSpacing.sp4,
                    PokeBinderSpacing.sp3,
                    PokeBinderSpacing.sp4,
                    PokeBinderSpacing.sp3,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: PillButton(
                          label: 'Cancel',
                          ghost: true,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      const SizedBox(width: PokeBinderSpacing.sp2),
                      Expanded(
                        flex: 3,
                        child: PillButton(
                          label: _isEditing ? 'Save Changes' : 'Add Card',
                          icon: _isEditing ? Icons.check : Icons.add,
                          onTap: _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Emphasis for the button names quoted in the duplicate note's instruction.
const TextStyle _kOwnedKeyword =
    TextStyle(fontWeight: FontWeight.bold, color: PokeBinderColors.ink);

/// How many owned copies the duplicate note lists before it offers "Show all".
const int _kOwnedCopiesPreview = 3;

/// Height shared by the condition dropdown and the quantity stepper, so the
/// two sit level side by side.
const double _kPairedFieldHeight = 52;

/// 2026-10-04 -> "Oct 4, 2026".
String _shortDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// A small heading that groups related fields.
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: PokeBinderSpacing.sp2,
        bottom: PokeBinderSpacing.sp3,
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: PokeBinderColors.redDeep),
          const SizedBox(width: PokeBinderSpacing.sp2),
          Text(label.toUpperCase(), style: PokeBinderText.eyebrow),
          const SizedBox(width: PokeBinderSpacing.sp2),
          Expanded(
            child: Container(
              height: 1,
              color: PokeBinderColors.ink.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

/// − 1 + control for the number of copies owned.
class _QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  static const _min = 1;
  static const _max = 999;

  const _QuantityStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final canDecrease = value > _min;
    final canIncrease = value < _max;

    return Container(
      height: _kPairedFieldHeight,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            label: 'Decrease quantity',
            enabled: canDecrease,
            onTap: () => onChanged(value - 1),
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: PokeBinderText.selectValue,
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            label: 'Increase quantity',
            enabled: canIncrease,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: enabled,
      child: Material(
        color: enabled
            ? PokeBinderColors.red.withValues(alpha: 0.1)
            : PokeBinderColors.ink.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: _kPairedFieldHeight - 10,
            height: _kPairedFieldHeight - 10,
            child: Icon(
              icon,
              size: 20,
              color: enabled ? PokeBinderColors.redDeep : PokeBinderColors.hint,
            ),
          ),
        ),
      ),
    );
  }
}

/// A small tappable pill for a quick action beside a field.
class _MiniAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  /// An outline instead of a filled pill, for actions that shouldn't compete
  /// with a primary one nearby.
  final bool quiet;

  const _MiniAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.quiet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: quiet
          ? Colors.transparent
          : PokeBinderColors.red.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: quiet
            ? BorderSide(color: PokeBinderColors.ink.withValues(alpha: 0.16))
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PokeBinderSpacing.sp3,
            vertical: PokeBinderSpacing.sp2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: PokeBinderColors.redDeep),
              const SizedBox(width: PokeBinderSpacing.sp1),
              Text(label, style: PokeBinderText.tagLabel(PokeBinderColors.redDeep)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A heads-up that the card is already in the collection. Lists the copies
/// the person owns, each with a shortcut to add to it instead of making a
/// second entry. Long lists show a few copies and expand on request.
///
/// Styled like the app's other list cards: white, hairline border, soft
/// shadow and thin dividers between rows.
class _OwnedNote extends StatefulWidget {
  final List<PokemonCardData> copies;
  final String selectedCondition;

  /// The printing being added, and the card's default printing (what an owned
  /// copy with no recorded finish counts as).
  final String? selectedFinish;
  final String? defaultFinish;
  final int addQuantity;
  final ValueChanged<PokemonCardData> onAdd;

  const _OwnedNote({
    required this.copies,
    required this.selectedCondition,
    required this.selectedFinish,
    required this.defaultFinish,
    required this.addQuantity,
    required this.onAdd,
  });

  @override
  State<_OwnedNote> createState() => _OwnedNoteState();
}

class _OwnedNoteState extends State<_OwnedNote> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final count = widget.copies.fold(0, (sum, c) => sum + c.quantityOwned);
    bool matches(PokemonCardData c) =>
        c.condition == widget.selectedCondition &&
        (widget.selectedFinish == null ||
            (c.finish ?? widget.defaultFinish) == widget.selectedFinish);
    // Copies in the condition being added come first, so they are never
    // hidden behind "Show all".
    final ordered = [
      ...widget.copies.where(matches),
      ...widget.copies.where((c) => !matches(c)),
    ];
    final collapsible = ordered.length > _kOwnedCopiesPreview;
    final visible = collapsible && !_showAll
        ? ordered.take(_kOwnedCopiesPreview).toList()
        : ordered;
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: PokeBinderColors.ink.withValues(alpha: 0.06),
    );

    // Entries that look identical in every way the row shows also get their
    // date added, so they can still be told apart; otherwise it is left out.
    String sameness(PokemonCardData c) =>
        '${c.condition}|${c.finish ?? widget.defaultFinish}|'
        '${c.binderName}|${c.page}';
    final alikeCounts = <String, int>{};
    for (final c in widget.copies) {
      alikeCounts.update(sameness(c), (n) => n + 1, ifAbsent: () => 1);
    }

    return Container(
      // Extra room above, so the card doesn't sit right under the section
      // heading.
      margin: const EdgeInsets.only(
        top: PokeBinderSpacing.sp3,
        bottom: PokeBinderSpacing.sp3,
      ),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        boxShadow: kCardElevation,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(PokeBinderSpacing.sp3),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 20, color: PokeBinderColors.goldDeep),
                  const SizedBox(width: PokeBinderSpacing.sp3),
                  Expanded(
                    child: Text('You Own $count ${count == 1 ? 'Copy' : 'Copies'}',
                        style: PokeBinderText.rowTitle),
                  ),
                ],
              ),
            ),
            divider,
            // The instruction sits on its own cream band, so it reads as a
            // separate step rather than a caption under the title.
            // A soft warm grey rather than the page's cream, so the band reads
            // as part of this card instead of the background showing through.
            Container(
              color: PokeBinderColors.ink.withValues(alpha: 0.04),
              padding: const EdgeInsets.all(PokeBinderSpacing.sp3),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_outlined,
                      size: 20, color: PokeBinderColors.goldDeep),
                  const SizedBox(width: PokeBinderSpacing.sp3),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: PokeBinderText.listRowSubtitle,
                        children: const [
                          TextSpan(text: 'Tap '),
                          TextSpan(text: 'Add', style: _kOwnedKeyword),
                          TextSpan(text: ' to raise a copy you own, or '),
                          // Non-breaking space: "Add Card" never splits
                          // across two lines.
                          TextSpan(
                              text: 'Add\u00A0Card', style: _kOwnedKeyword),
                          TextSpan(text: ' to save a new entry.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final copy in visible) ...[
              divider,
              _OwnedCopyRow(
                copy: copy,
                selected: matches(copy),
                showDate: (alikeCounts[sameness(copy)] ?? 1) > 1,
                addQuantity: widget.addQuantity,
                onAdd: () => widget.onAdd(copy),
              ),
            ],
            if (collapsible) ...[
              divider,
              Material(
                color: PokeBinderColors.white,
                child: InkWell(
                  onTap: () => setState(() => _showAll = !_showAll),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: PokeBinderSpacing.sp3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showAll
                              ? 'Show Fewer'
                              : 'Show All ${ordered.length} Entries',
                          style: PokeBinderText.backLink,
                        ),
                        const SizedBox(width: PokeBinderSpacing.sp1),
                        Icon(
                          _showAll
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: PokeBinderColors.redDeep,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One owned entry: its condition, how many, and the binder, plus an add
/// button. The entry matching the condition picked in the form gets a gold
/// edge and a faint gold wash.
class _OwnedCopyRow extends StatelessWidget {
  final PokemonCardData copy;
  final bool selected;

  /// Whether to show when this entry was added — only needed when another
  /// entry looks exactly the same.
  final bool showDate;
  final int addQuantity;
  final VoidCallback onAdd;

  const _OwnedCopyRow({
    required this.copy,
    required this.selected,
    required this.showDate,
    required this.addQuantity,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final condition = kConditionOptions
        .firstWhere((o) => o.$2 == copy.condition,
            orElse: () => (copy.condition, copy.condition))
        .$1;
    final inBinder = copy.binderName != kUnassignedBinderName;
    final where = inBinder ? '${copy.binderName} · p.${copy.page}' : 'No binder';
    final title = copy.finish == null
        ? condition
        : '$condition · ${finishLabel(copy.finish!)}';

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(PokeBinderSpacing.sp3),
          color: selected ? PokeBinderColors.gold.withValues(alpha: 0.08) : null,
          child: Row(
            children: [
              Icon(conditionIconFor(copy.condition),
                  size: 18, color: PokeBinderColors.teal),
              const SizedBox(width: PokeBinderSpacing.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PokeBinderText.rowTitle,
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: PokeBinderSpacing.sp2),
                          const _MatchTag(),
                        ],
                      ],
                    ),
                    const SizedBox(height: PokeBinderSpacing.sp0),
                    Wrap(
                      spacing: PokeBinderSpacing.sp2,
                      runSpacing: PokeBinderSpacing.sp0,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('${copy.quantityOwned} owned',
                            style: PokeBinderText.listRowSubtitle
                                .copyWith(fontWeight: FontWeight.w600)),
                        _OwnedMeta(
                          icon: Icons.folder_outlined,
                          text: where,
                          maxWidth: 170,
                        ),
                        if (showDate)
                          _OwnedMeta(
                            icon: Icons.event_outlined,
                            text: 'Added ${_shortDate(copy.dateAdded)}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp2),
              // The entry matching what is being added gets the filled
              // button; the others are quieter outlines.
              _MiniAction(
                label: 'Add $addQuantity',
                icon: Icons.add_rounded,
                quiet: !selected,
                onTap: onAdd,
              ),
            ],
          ),
        ),
        // An inset gold edge: unlike a full-height border, two highlighted
        // rows in a row keep a gap between their bars.
        if (selected)
          Positioned(
            left: 0,
            top: PokeBinderSpacing.sp3,
            bottom: PokeBinderSpacing.sp3,
            child: Container(
              width: 3,
              decoration: const BoxDecoration(
                color: PokeBinderColors.gold,
                borderRadius:
                    BorderRadius.horizontal(right: Radius.circular(3)),
              ),
            ),
          ),
      ],
    );
  }
}

/// Marks the owned entry that matches the condition (and finish) being added.
class _MatchTag extends StatelessWidget {
  const _MatchTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: PokeBinderColors.gold.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'MATCH',
        style: PokeBinderText.tagLabel(PokeBinderColors.ink)
            .copyWith(fontSize: 9, letterSpacing: 0.6),
      ),
    );
  }
}

/// One selectable printing (Normal, Holofoil ...) with its market price.
class _FinishChip extends StatelessWidget {
  final String label;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  const _FinishChip({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $price',
      child: Material(
        color: selected
            ? PokeBinderColors.red.withValues(alpha: 0.1)
            : PokeBinderColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected
                ? PokeBinderColors.red.withValues(alpha: 0.55)
                : PokeBinderColors.ink.withValues(alpha: 0.1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PokeBinderSpacing.sp3,
              vertical: PokeBinderSpacing.sp3,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check_rounded,
                      size: 15, color: PokeBinderColors.red),
                  const SizedBox(width: PokeBinderSpacing.sp1),
                ],
                Text(label, style: PokeBinderText.pillLabel(selected: selected)),
                const SizedBox(width: PokeBinderSpacing.sp2),
                Text(price, style: PokeBinderText.listRowSubtitle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small icon-and-text detail in an owned-copy row.
class _OwnedMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  final double maxWidth;

  const _OwnedMeta({
    required this.icon,
    required this.text,
    this.maxWidth = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: PokeBinderColors.inkSoft),
        const SizedBox(width: PokeBinderSpacing.sp1),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PokeBinderText.listRowSubtitle,
          ),
        ),
      ],
    );
  }
}

/// A rounded label for a card trait (rarity, type, subtype).
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: PokeBinderSpacing.chip,
      decoration: BoxDecoration(
        color: highlight
            ? PokeBinderColors.gold.withValues(alpha: 0.2)
            : PokeBinderColors.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: highlight
                ? PokeBinderColors.goldDeep
                : PokeBinderColors.inkSoft,
          ),
          const SizedBox(width: PokeBinderSpacing.sp1),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: PokeBinderText.tagLabel(
                highlight ? PokeBinderColors.ink : PokeBinderColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The read-only identity of a catalog card: artwork, name, set and number,
/// traits, and the market price. Shown instead of editable fields so none of
/// it can be mistyped.
class _CatalogSummary extends StatelessWidget {
  final String name;
  final String setName;
  final String number;
  final String rarity;
  final PokemonCardType type;
  final CardSupertype supertype;
  final String? subtype;
  final String? imagePath;
  final bool showPrice;
  final double? priceUsd;
  final double? pricePhp;
  final DateTime? priceUpdatedAt;

  /// The printing the price is for ("Holofoil"), when the card has several.
  final String? priceCaption;

  /// The owned copy's printing, shown as a chip when editing.
  final String? finishChip;

  const _CatalogSummary({
    required this.name,
    required this.setName,
    required this.number,
    required this.rarity,
    required this.type,
    required this.supertype,
    required this.subtype,
    required this.imagePath,
    required this.showPrice,
    required this.priceUsd,
    required this.pricePhp,
    required this.priceUpdatedAt,
    this.priceCaption,
    this.finishChip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: PokeBinderSpacing.sp5),
      padding: const EdgeInsets.all(PokeBinderSpacing.sp4),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.09)),
        boxShadow: kCardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tapping the artwork opens it full size, so the printing can be
              // checked. There is no ripple or hint: nothing changes visually.
              Semantics(
                button: true,
                label: 'View $name full size',
                child: GestureDetector(
                  onTap: imagePath == null
                      ? null
                      : () => showCardViewer(context, imagePath: imagePath!),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: PokeBinderColors.ink.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CardThumbnail(
                      card: null,
                      imageAssetPath: imagePath,
                      width: 128,
                      height: 179,
                      borderRadius: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PokeBinderText.headingSm,
                    ),
                    if (setName.isNotEmpty) ...[
                      const SizedBox(height: PokeBinderSpacing.sp1),
                      Text(setName, style: PokeBinderText.subtitle),
                    ],
                    if (number.isNotEmpty) ...[
                      const SizedBox(height: PokeBinderSpacing.sp0),
                      Text('Card #$number', style: PokeBinderText.listRowSubtitle),
                    ],
                    const SizedBox(height: PokeBinderSpacing.sp3),
                    Wrap(
                      spacing: PokeBinderSpacing.sp2,
                      runSpacing: PokeBinderSpacing.sp2,
                      children: [
                        _InfoChip(
                          icon: rarityIconFor(rarity),
                          label: rarity,
                          highlight: true,
                        ),
                        if (supertype != CardSupertype.trainer)
                          _InfoChip(
                            icon: type.typeIcon,
                            label: _capitalize(type.name),
                          ),
                        if (subtype != null && subtype!.isNotEmpty)
                          _InfoChip(
                            icon: Icons.label_outline_rounded,
                            label: subtype!,
                          ),
                        if (finishChip != null)
                          _InfoChip(
                            icon: Icons.auto_awesome_outlined,
                            label: finishChip!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showPrice) ...[
            const SizedBox(height: PokeBinderSpacing.sp4),
            _PricePanel(
              usd: priceUsd,
              php: pricePhp,
              updatedAt: priceUpdatedAt,
              caption: priceCaption,
            ),
          ],
          const SizedBox(height: PokeBinderSpacing.sp3),
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 12, color: PokeBinderColors.inkSoft),
              const SizedBox(width: PokeBinderSpacing.sp1),
              Flexible(
                child: Text(
                  'Details come from the card database',
                  style: PokeBinderText.listRowSubtitle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The market price as a headline figure, with the dollar price and the date
/// it was last updated alongside.
class _PricePanel extends StatelessWidget {
  final double? usd;
  final double? php;
  final DateTime? updatedAt;

  /// Which printing the price is for, shown after the heading.
  final String? caption;

  const _PricePanel({
    required this.usd,
    required this.php,
    required this.updatedAt,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrice = usd != null && php != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: PokeBinderSpacing.sp4,
        vertical: PokeBinderSpacing.sp3,
      ),
      decoration: BoxDecoration(
        color: PokeBinderColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PokeBinderColors.gold.withValues(alpha: 0.4),
        ),
      ),
      child: hasPrice
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caption == null
                            ? 'MARKET PRICE'
                            : 'MARKET PRICE · ${caption!.toUpperCase()}',
                        style: PokeBinderText.sectionLabel,
                      ),
                      const SizedBox(height: PokeBinderSpacing.sp0),
                      Text(formatPeso(php!), style: PokeBinderText.statNumber),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('US\$${usd!.toStringAsFixed(2)}',
                        style: PokeBinderText.rowTitle),
                    if (updatedAt != null) ...[
                      const SizedBox(height: PokeBinderSpacing.sp0),
                      Text('Updated ${_shortDate(updatedAt!)}',
                          style: PokeBinderText.listRowSubtitle),
                    ],
                  ],
                ),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: PokeBinderColors.inkSoft),
                const SizedBox(width: PokeBinderSpacing.sp2),
                Expanded(
                  child: Text(
                    'No market price on file for this card. '
                    'Enter a value below.',
                    style: PokeBinderText.listRowSubtitle,
                  ),
                ),
              ],
            ),
    );
  }
}