import 'package:flutter/material.dart';
import '../config/pricing.dart';
import '../models/binder_data.dart';
import '../models/catalog_card.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/card_form_parts.dart';
import '../widgets/catalog_card_summary.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';

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
  }) : assert(existingCard != null || catalogCard != null,
            'Pass a catalogCard to add a card, or an existingCard to edit one.');

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  static String? _lastBinderId;
  static int? _lastPage;
  static String? _lastCondition;

  String? get _catalogId => widget.existingCard?.catalogId ?? widget.catalogCard?.id;

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

  late String? _finish =
      widget.existingCard?.finish ?? widget.catalogCard?.defaultFinish;

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

  String? _quantityError;

  bool _valueEdited = false;

  bool get _isEditing => widget.existingCard != null;

  String get _title => _isEditing ? 'Edit Card' : 'Add to Collection';

  String get _subtitle => _isEditing
      ? 'Update the details below.'
      : 'Confirm the details of your copy.';

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

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity < 1) {
      setState(() => _quantityError = 'Quantity must be at least 1.');
      return;
    }

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

    final card = PokemonCardData(
      id: widget.existingCard?.id ?? 'card-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      setName: _setController.text.trim(),
      cardNumber: _cardNumberController.text.trim(),
      rarity: _rarity,
      type: _type,
      supertype: _supertype,
      subtype: _subtype,
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
    final confirmed = await confirmDestructive(
      context,
      title: 'Delete card?',
      message: 'This removes "${card.name}" from your collection. '
          "This can't be undone.",
      confirmLabel: 'Delete',
    );

    if (confirmed && mounted) {
      Navigator.of(context).pop(const CardFormResult.deleted());
    }
  }

  double? get _marketUsd => widget.catalogCard?.priceUsdFor(_finish);

  double? get _marketPhp {
    final usd = _marketUsd;
    return usd == null ? null : roundPeso(usd * kUsdToPhpRate);
  }

  double? get _suggestedValue {
    final nearMint = _isEditing ? null : _marketPhp;
    return nearMint == null ? null : priceForCondition(nearMint, _conditionCode);
  }

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

  List<String> get _finishes => widget.catalogCard?.finishes ?? const [];

  BinderData? get _selectedBinder {
    if (_binderId == kUnassignedBinderId) return null;
    for (final b in widget.binders) {
      if (b.id == _binderId) return b;
    }
    return null;
  }

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

                    CatalogSummary(
                      name: _nameController.text,
                      setName: _setController.text,
                      number: _cardNumberController.text,
                      rarity: _rarity,
                      type: _type,
                      supertype: _supertype,
                      subtype: _subtype,
                      imagePath: widget.existingCard?.imageAssetPath ??
                          widget.catalogCard?.collectionImage,
                      showPrice: !_isEditing && widget.catalogCard != null,
                      priceUsd: _marketUsd,
                      pricePhp: _marketPhp,
                      priceUpdatedAt: widget.catalogCard?.priceUpdatedAt,
                      priceCaption: _finishes.length > 1 && _finish != null
                          ? finishLabel(_finish!)
                          : null,
                      finishChip: _isEditing && _finish != null
                          ? finishLabel(_finish!)
                          : null,
                    ),

                    const FormSectionTitle(
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
                              FinishChip(
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
                          height: kPairedFieldHeight,
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
                            child: QuantityStepper(
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

                    EstimatedValueField(
                      controller: _valueController,
                      suggested: suggested,
                      edited: _valueEdited,
                      onChanged: (text) => setState(() => _valueEdited =
                          text.trim() != _suggestedValue?.toStringAsFixed(0)),
                      onUseSuggested: () => setState(() {
                        _valueController.text = suggested!.toStringAsFixed(0);
                        _valueEdited = false;
                      }),
                    ),

                    const FormSectionTitle(
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
                      DangerActionButton(label: 'Delete Card', onTap: _confirmDelete),
                    ],
                  ],
                ),
              ),
            ),

            FormActionBar(
              label: _isEditing ? 'Save Changes' : 'Add Card',
              icon: _isEditing ? Icons.check : Icons.add,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

const TextStyle _kOwnedKeyword =
    TextStyle(fontWeight: FontWeight.bold, color: PokeBinderColors.ink);

const int _kOwnedCopiesPreview = 3;

class _OwnedNote extends StatefulWidget {
  final List<PokemonCardData> copies;
  final String selectedCondition;

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

    String sameness(PokemonCardData c) =>
        '${c.condition}|${c.finish ?? widget.defaultFinish}|'
        '${c.binderName}|${c.page}';
    final alikeCounts = <String, int>{};
    for (final c in widget.copies) {
      alikeCounts.update(sameness(c), (n) => n + 1, ifAbsent: () => 1);
    }

    return Container(
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

class _OwnedCopyRow extends StatelessWidget {
  final PokemonCardData copy;
  final bool selected;

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
                            text: 'Added ${shortDate(copy.dateAdded)}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp2),
              MiniAction(
                label: 'Add $addQuantity',
                icon: Icons.add_rounded,
                quiet: !selected,
                onTap: onAdd,
              ),
            ],
          ),
        ),
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
