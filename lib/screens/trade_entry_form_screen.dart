import 'package:flutter/material.dart';
import '../models/pokemon_card_data.dart';
import '../models/wishlist_entry.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';
import 'wishlist_form_result.dart';

/// Edit an existing Trade List entry — cards ready to trade away. New trade
/// entries are added by picking cards straight out of the collection via
/// [TradeListAddCardScreen]; this screen only ever edits one already there.
class TradeEntryFormScreen extends StatefulWidget {
  final WishlistEntry existingEntry;

  const TradeEntryFormScreen({
    super.key,
    required this.existingEntry,
  });

  @override
  State<TradeEntryFormScreen> createState() => _TradeEntryFormScreenState();
}

class _TradeEntryFormScreenState extends State<TradeEntryFormScreen> {
  late final _nameController =
      TextEditingController(text: widget.existingEntry.name);
  late final _setController =
      TextEditingController(text: widget.existingEntry.setName);
  late final _cardNumberController =
      TextEditingController(text: widget.existingEntry.cardNumber);
  late final _qtyController =
      TextEditingController(text: '${widget.existingEntry.quantity}');
  late final _valueController = TextEditingController(
    text: widget.existingEntry.estimatedValue > 0
        ? widget.existingEntry.estimatedValue.toStringAsFixed(0)
        : '',
  );
  late final _askingForController =
      TextEditingController(text: widget.existingEntry.askingFor);
  late final _notesController =
      TextEditingController(text: widget.existingEntry.notes);

  late WishlistPriority _priority = widget.existingEntry.priority;
  late String _rarity = widget.existingEntry.rarity;
  late String _conditionCode = kConditionOptions.firstWhere(
    (option) => option.$2 == widget.existingEntry.condition,
    orElse: () => kConditionOptions.first,
  ).$2;

  String? _nameError;
  String? _setError;
  String? _cardNumberError;
  String? _quantityError;

  @override
  void dispose() {
    _nameController.dispose();
    _setController.dispose();
    _cardNumberController.dispose();
    _qtyController.dispose();
    _valueController.dispose();
    _askingForController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Give the card a name first.');
      return;
    }

    final setName = _setController.text.trim();
    if (setName.isEmpty) {
      setState(() => _setError = 'Which set is this card from?');
      return;
    }

    final cardNumber = _cardNumberController.text.trim();
    if (cardNumber.isEmpty) {
      setState(() => _cardNumberError = "Add the card's number.");
      return;
    }

    final qty = int.tryParse(_qtyController.text);
    if (qty == null || qty < 1) {
      setState(() => _quantityError = 'Quantity must be at least 1.');
      return;
    }

    final entry = WishlistEntry(
      id: widget.existingEntry.id,
      name: name,
      setName: setName,
      cardNumber: cardNumber,
      rarity: _rarity,
      condition: _conditionCode,
      quantity: qty,
      notes: _notesController.text.trim(),
      kind: WishlistEntryKind.trade,
      priority: _priority,
      estimatedValue: double.tryParse(_valueController.text.trim()) ?? 0,
      askingFor: _askingForController.text.trim(),
      sourceCardId: widget.existingEntry.sourceCardId,
      dateAdded: widget.existingEntry.dateAdded,
    );

    Navigator.of(context).pop(WishlistFormResult.saved(entry));
  }

  Future<void> _confirmDelete() async {
    final entry = widget.existingEntry;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove entry?'),
        content: Text(
          'This removes "${entry.name}" from your trade list. '
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
              'Remove',
              style: TextStyle(color: PokeBinderColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop(const WishlistFormResult.deleted());
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
                label: '‹ Back',
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('Edit Trade Entry', style: PokeBinderText.heading),
              const SizedBox(height: 4),
              Text(
                "List a card you're ready to trade away.",
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),

              LabeledFormField(
                label: 'Card name',
                child: TextField(
                  controller: _nameController,
                  decoration: pokeInputDecoration(
                    hint: 'e.g. Pikachu VMAX',
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
                    onChanged: (_) {
                      if (_setError != null) setState(() => _setError = null);
                    },
                  ),
                ),
                right: LabeledFormField(
                  label: 'Card Number',
                  child: TextField(
                    controller: _cardNumberController,
                    decoration: pokeInputDecoration(
                      hint: '4/102',
                      icon: Icons.tag_rounded,
                    ),
                    onChanged: (_) {
                      if (_cardNumberError != null) {
                        setState(() => _cardNumberError = null);
                      }
                    },
                  ),
                ),
              ),
              if (_setError != null || _cardNumberError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp2),
                  child: Text(
                    _setError ?? _cardNumberError!,
                    style: PokeBinderText.formError,
                  ),
                ),

              FormFieldRow(
                left: LabeledFormField(
                  label: 'Rarity',
                  child: PokeDropdownField<String>(
                    value: _rarity,
                    icon: Icons.diamond_rounded,
                    options: [
                      for (final r in kRarityOptions)
                        PokeDropdownOption(r, r, icon: rarityIconFor(r)),
                    ],
                    onChanged: (r) => setState(() => _rarity = r),
                  ),
                ),
                right: LabeledFormField(
                  label: 'Condition',
                  child: PokeDropdownField<String>(
                    value: _conditionCode,
                    icon: Icons.health_and_safety_outlined,
                    options: [
                      for (final c in kConditionOptions)
                        PokeDropdownOption(c.$2, c.$1,
                            icon: conditionIconFor(c.$2)),
                    ],
                    onChanged: (c) => setState(() => _conditionCode = c),
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
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: pokeInputDecoration(
                          hint: '1',
                          icon: Icons.style_outlined,
                        ),
                        onChanged: (_) {
                          if (_quantityError != null) {
                            setState(() => _quantityError = null);
                          }
                        },
                      ),
                    ),
                    if (_quantityError != null)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: PokeBinderSpacing.sp2),
                        child:
                            Text(_quantityError!, style: PokeBinderText.formError),
                      ),
                  ],
                ),
                right: LabeledFormField(
                  label: 'Est. value (optional)',
                  child: TextField(
                    controller: _valueController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: pokeInputDecoration(
                      hint: '₱0',
                      icon: Icons.payments_outlined,
                    ),
                  ),
                ),
              ),

              LabeledFormField(
                label: 'Eagerness to trade',
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
                label: 'Looking for in return (optional)',
                child: TextField(
                  controller: _askingForController,
                  minLines: 2,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: pokeInputDecoration(
                    hint: 'e.g. Pikachu VMAX or store credit',
                  ),
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
                            'Remove entry',
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
          ),
        ),
      ),
    );
  }
}