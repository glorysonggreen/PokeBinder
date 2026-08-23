import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';

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
    text: '${widget.existingBinder?.pageCount ?? 1}',
  );

  late int _slotsPerPage = widget.existingBinder?.slotsPerPage ?? 6;

  String? _nameError;
  String? _pagesError;

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
    final requestedPages = int.tryParse(_pagesController.text);
    if (requestedPages == null || requestedPages < 1) {
      setState(() => _pagesError = 'Starting pages must be at least 1.');
      return;
    }
    final pageCount = requestedPages < minPages ? minPages : requestedPages;

    final pages = <List<PokemonCardData>>[
      if (existing != null) ...existing.pages,
      for (var i = (existing?.pageCount ?? 0); i < pageCount; i++)
        <PokemonCardData>[],
    ];

    final binder = BinderData(
      id: existing?.id ?? 'binder-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
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
                    ? 'Update the details — pages already in this binder '
                        'stay put.'
                    : 'Give it a name and starting size — you can add cards '
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
                  padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp2),
                  child: Text(_nameError!, style: PokeBinderText.formError),
                ),

              FormFieldRow(
                left: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabeledFormField(
                      label: 'Starting pages',
                      child: TextField(
                        controller: _pagesController,
                        keyboardType: TextInputType.number,
                        decoration: pokeInputDecoration(),
                        onChanged: (_) {
                          if (_pagesError != null) {
                            setState(() => _pagesError = null);
                          }
                        },
                      ),
                    ),
                    if (_pagesError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp2),
                        child: Text(_pagesError!, style: PokeBinderText.formError),
                      ),
                  ],
                ),
                right: LabeledFormField(
                  label: 'Slots per page',
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _slotsPerPage,
                    decoration: pokeInputDecoration(),
                    items: const [6, 9, 12, 15]
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
                  keyboardType: TextInputType.multiline,
                  minLines: 3,
                  maxLines: 5,
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
                      label: _isEditing ? 'Save Changes' : 'Create Binder',
                      icon: _isEditing ? Icons.check : Icons.add,
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
                      padding: EdgeInsets.symmetric(
                        vertical: PokeBinderSpacing.sp2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 14,
                            color: PokeBinderColors.danger,
                          ),
                          SizedBox(width: PokeBinderSpacing.sp2),
                          Text(
                            'Delete Binder',
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}