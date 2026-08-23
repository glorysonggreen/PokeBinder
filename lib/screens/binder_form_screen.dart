import 'package:flutter/material.dart';

import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';

/// What the Add/Edit Binder screen hands back to the caller when it pops.
/// Exactly one of [binder] or [deleted] applies:
/// - Cancel: the screen pops with no result at all (null), nothing to do.
/// - Create/Save: pops with `BinderFormResult.saved(binder)`.
/// - Delete: pops with `BinderFormResult.deleted()`.
class BinderFormResult {
  final BinderData? binder;
  final bool deleted;

  const BinderFormResult.saved(BinderData binder)
      : binder = binder,
        deleted = false;

  const BinderFormResult.deleted()
      : binder = null,
        deleted = true;
}

/// The cover colors offered when creating or editing a binder. `colorless`
/// (used for cards like Jigglypuff) is left out here since the mockup's
/// New Binder screen only offers five swatches.
const _kBinderCoverOptions = [
  PokemonCardType.fire,
  PokemonCardType.water,
  PokemonCardType.lightning,
  PokemonCardType.psychic,
  PokemonCardType.grass,
];

/// Add/Edit Binder screen. Pass [existingBinder] to edit (and offer
/// deleting) that binder; leave it null to create a new one.
class BinderFormScreen extends StatefulWidget {
  final BinderData? existingBinder;

  const BinderFormScreen({super.key, this.existingBinder});

  @override
  State<BinderFormScreen> createState() => _BinderFormScreenState();
}

class _BinderFormScreenState extends State<BinderFormScreen> {
  late final _nameController =
      TextEditingController(text: widget.existingBinder?.name ?? '');
  late final _descriptionController =
      TextEditingController(text: widget.existingBinder?.description ?? '');
  late final _pagesController = TextEditingController(
    text: '${widget.existingBinder?.pageCount ?? 4}',
  );

  late PokemonCardType _accentType =
      widget.existingBinder?.accentType ?? _kBinderCoverOptions.first;
  late int _slotsPerPage = widget.existingBinder?.slotsPerPage ?? 9;

  String? _nameError;

  bool get _isEditing => widget.existingBinder != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pagesController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Give your binder a name first.');
      return;
    }

    final existing = widget.existingBinder;
    // Pages already in the binder always stay — this field can only grow
    // the binder, never shrink it out from under existing cards.
    final minPages = existing?.pageCount ?? 1;
    final requestedPages = int.tryParse(_pagesController.text) ?? minPages;
    final pageCount = requestedPages < minPages ? minPages : requestedPages;

    final pages = <List<PokemonCardData>>[
      if (existing != null) ...existing.pages,
      for (var i = (existing?.pageCount ?? 0); i < pageCount; i++)
        <PokemonCardData>[],
    ];

    final binder = BinderData(
      id: existing?.id ?? 'binder-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      accentType: _accentType,
      description: _descriptionController.text.trim(),
      slotsPerPage: _slotsPerPage,
      pages: pages,
    );

    Navigator.of(context).pop(BinderFormResult.saved(binder));
  }

  Future<void> _confirmDelete() async {
    final binder = widget.existingBinder!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete binder?'),
        content: Text(
          'This removes "${binder.name}" and all ${binder.cardCount} '
          "cards in it. This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: PokeBinderColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop(const BinderFormResult.deleted());
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
                label: '‹ Binders',
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text(
                _isEditing ? 'Edit Binder' : 'New Binder',
                style: PokeBinderText.eyebrow,
              ),
              const SizedBox(height: 4),
              Text(
                _isEditing ? 'Edit binder' : 'Create a binder',
                style: PokeBinderText.heading,
              ),
              const SizedBox(height: 4),
              Text(
                _isEditing
                    ? 'Update the name or cover — pages already in this '
                        'binder stay put.'
                    : "Give it a name and pick a cover — you can add cards "
                        'to it right after.',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),

              LabeledFormField(
                label: 'Binder name',
                child: TextField(
                  controller: _nameController,
                  decoration: pokeInputDecoration(hint: 'e.g. Johto Journey'),
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                ),
              ),
              if (_nameError != null)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: PokeBinderSpacing.sp2,
                    top: -6,
                  ),
                  child: Text(_nameError!, style: PokeBinderText.formError),
                ),

              LabeledFormField(
                label: 'Cover color',
                child: BinderCoverSwatchPicker(
                  options: _kBinderCoverOptions,
                  selected: _accentType,
                  onChanged: (type) => setState(() => _accentType = type),
                ),
              ),

              FormFieldRow(
                left: LabeledFormField(
                  label: 'Starting pages',
                  child: TextField(
                    controller: _pagesController,
                    keyboardType: TextInputType.number,
                    decoration: pokeInputDecoration(),
                  ),
                ),
                right: LabeledFormField(
                  label: 'Slots per page',
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _slotsPerPage,
                    decoration: pokeInputDecoration(),
                    items: const [9, 4, 6, 12]
                        .map((n) =>
                            DropdownMenuItem(value: n, child: Text('$n')))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _slotsPerPage = value);
                    },
                  ),
                ),
              ),

              LabeledFormField(
                label: 'Description (optional)',
                child: TextField(
                  controller: _descriptionController,
                  decoration:
                      pokeInputDecoration(hint: "What's this binder for?"),
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
                      label: _isEditing ? 'Save changes' : '＋ Create binder',
                      onTap: _submit,
                    ),
                  ),
                ],
              ),

              if (_isEditing) ...[
                const SizedBox(height: PokeBinderSpacing.sp4),
                Center(
                  child: InkWell(
                    onTap: _confirmDelete,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Delete binder',
                        style: TextStyle(
                          color: PokeBinderColors.danger,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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