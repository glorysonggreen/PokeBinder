import 'package:flutter/material.dart';
import '../config/pricing.dart';
import '../models/catalog_card.dart';
import '../models/pokemon_card_data.dart';
import '../models/wishlist_entry.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/card_form_parts.dart';
import '../widgets/catalog_card_summary.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';
import 'wishlist_form_result.dart';
import '../widgets/pokebinder_background.dart';

class WishlistFormScreen extends StatefulWidget {
  final CatalogCard? catalogCard;
  final WishlistEntry? existingEntry;

  const WishlistFormScreen({super.key, this.catalogCard, this.existingEntry})
      : assert(catalogCard != null || existingEntry != null);

  @override
  State<WishlistFormScreen> createState() => _WishlistFormScreenState();
}

class _WishlistFormScreenState extends State<WishlistFormScreen> {
  late final _valueController = TextEditingController(
    text: _isEditing
        ? widget.existingEntry!.estimatedValue.toStringAsFixed(0)
        : _suggestedValue?.toStringAsFixed(0) ?? '',
  );
  late final _notesController =
      TextEditingController(text: widget.existingEntry?.notes ?? '');

  late int _quantity = widget.existingEntry?.quantity ?? 1;
  late WishlistPriority _priority =
      widget.existingEntry?.priority ?? WishlistPriority.medium;
  late String _conditionCode = kConditionOptions.firstWhere(
    (option) => option.$2 == widget.existingEntry?.condition,
    orElse: () => kConditionOptions.first,
  ).$2;
  late String? _finish =
      widget.existingEntry?.finish ?? widget.catalogCard?.defaultFinish;
  bool _valueEdited = false;

  bool get _isEditing => widget.existingEntry != null;

  String get _name =>
      widget.existingEntry?.name ?? widget.catalogCard?.name ?? '';
  String get _setName =>
      widget.existingEntry?.setName ?? widget.catalogCard?.setName ?? '';
  String get _cardNumber =>
      widget.existingEntry?.cardNumber ??
      widget.catalogCard?.displayNumber ??
      '';
  String get _rarity =>
      widget.existingEntry?.rarity ??
      widget.catalogCard?.rarity ??
      kRarityOptions.first;
  String? get _imagePath =>
      widget.existingEntry?.imageAssetPath ??
      widget.catalogCard?.collectionImage;

  List<String> get _finishes => widget.catalogCard?.finishes ?? const [];

  double? get _marketUsd => widget.catalogCard?.priceUsdFor(_finish);

  double? get _marketPhp {
    final usd = _marketUsd;
    return usd == null ? null : roundPeso(usd * kUsdToPhpRate);
  }

  double? get _suggestedValue {
    final nearMint = _isEditing ? null : _marketPhp;
    return nearMint == null ? null : priceForCondition(nearMint, _conditionCode);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
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

  void _submit() {
    final existing = widget.existingEntry;
    final entry = WishlistEntry(
      id: existing?.id ?? 'wishlist-${DateTime.now().microsecondsSinceEpoch}',
      name: _name,
      setName: _setName,
      cardNumber: _cardNumber,
      rarity: _rarity,
      condition: _conditionCode,
      quantity: _quantity,
      notes: _notesController.text.trim(),
      kind: WishlistEntryKind.wishlist,
      priority: _priority,
      estimatedValue: _parsedValue(_valueController.text),
      imageAssetPath: _imagePath,
      catalogId: existing?.catalogId ?? widget.catalogCard?.id,
      finish: _finish,
      dateAdded: existing?.dateAdded ?? DateTime.now(),
    );

    Navigator.of(context).pop(WishlistFormResult.saved(entry));
  }

  Future<void> _confirmDelete() async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Remove entry?',
      message: 'This removes "$_name" from your wishlist. '
          "This can't be undone.",
      confirmLabel: 'Remove',
    );

    if (confirmed && mounted) {
      Navigator.of(context).pop(const WishlistFormResult.deleted());
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggested = _suggestedValue;
    final finish = _finish;

    return PokeBinderScaffold(
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
                    Text(
                      _isEditing ? 'Edit Wishlist Card' : 'Add to Wishlist',
                      style: PokeBinderText.heading,
                    ),
                    const SizedBox(height: PokeBinderSpacing.sp1),
                    Text(
                      _isEditing
                          ? 'Update the details below.'
                          : "Track a card you're hoping to pull or pick up.",
                      style: PokeBinderText.subtitle,
                    ),
                    const SizedBox(height: PokeBinderSpacing.sp4),
                    CatalogSummary(
                      name: _name,
                      setName: _setName,
                      number: _cardNumber,
                      rarity: _rarity,
                      type: widget.catalogCard?.type,
                      supertype: widget.catalogCard?.supertype,
                      subtype: widget.catalogCard?.subtype,
                      imagePath: _imagePath,
                      showPrice: !_isEditing && widget.catalogCard != null,
                      priceUsd: _marketUsd,
                      pricePhp: _marketPhp,
                      priceUpdatedAt: widget.catalogCard?.priceUpdatedAt,
                      priceCaption: _finishes.length > 1 && finish != null
                          ? finishLabel(finish)
                          : null,
                      finishChip: _isEditing && finish != null
                          ? finishLabel(finish)
                          : null,
                    ),
                    const FormSectionTitle(
                      icon: Icons.favorite_border_rounded,
                      label: 'Your wish',
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
                            for (final option in _finishes)
                              FinishChip(
                                label: finishLabel(option),
                                price: formatPeso(roundPeso(
                                    widget.catalogCard!.finishPrices[option]! *
                                        kUsdToPhpRate)),
                                selected: option == finish,
                                onTap: () => _setFinish(option),
                              ),
                          ],
                        ),
                      ),
                    ],
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
                      right: LabeledFormField(
                        label: 'Quantity',
                        child: QuantityStepper(
                          value: _quantity,
                          onChanged: (value) =>
                              setState(() => _quantity = value),
                        ),
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
                    LabeledFormField(
                      label: 'Priority',
                      child: PokeDropdownField<WishlistPriority>(
                        value: _priority,
                        icon: Icons.flag_rounded,
                        options: [
                          for (final p in WishlistPriority.values)
                            PokeDropdownOption(p, p.label, icon: p.icon),
                        ],
                        onChanged: (p) => setState(() => _priority = p),
                      ),
                    ),
                    LabeledFormField(
                      label: 'Notes (optional)',
                      child: TextField(
                        controller: _notesController,
                        minLines: 2,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        decoration: pokeInputDecoration(
                          hint: 'Condition, max price, etc.',
                        ),
                      ),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: PokeBinderSpacing.sp3),
                      DangerActionButton(
                        label: 'Remove entry',
                        onTap: _confirmDelete,
                      ),
                    ],
                    const SizedBox(height: PokeBinderSpacing.sp4),
                  ],
                ),
              ),
            ),
            FormActionBar(
              label: _isEditing ? 'Save Changes' : 'Add to Wishlist',
              icon: _isEditing ? Icons.check : Icons.add,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

double _parsedValue(String text) {
  final value = double.tryParse(text.trim());
  return value != null && value.isFinite && value > 0 ? value : 0.0;
}
