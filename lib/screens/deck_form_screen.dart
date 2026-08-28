import 'package:flutter/material.dart';
import '../models/deck_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';

const _kSizePresets = [15, 20, 30, 40, 60];

class DeckFormResult {
  final DeckData? deck;
  final bool deleted;

  const DeckFormResult.saved(DeckData deck)
      : deck = deck,
        deleted = false;

  const DeckFormResult.deleted()
      : deck = null,
        deleted = true;
}

class DeckFormScreen extends StatefulWidget {
  final DeckData? existingDeck;

  const DeckFormScreen({super.key, this.existingDeck});

  @override
  State<DeckFormScreen> createState() => _DeckFormScreenState();
}

class _DeckFormScreenState extends State<DeckFormScreen> {
  late final _nameController =
      TextEditingController(text: widget.existingDeck?.name ?? '');
  late final _descriptionController =
      TextEditingController(text: widget.existingDeck?.description ?? '');

  late DeckFormat _format = widget.existingDeck?.format ?? DeckFormat.standard;
  late int _targetSize = widget.existingDeck?.targetSize ?? 60;

  String? _nameError;

  bool get _isEditing => widget.existingDeck != null;

  /// The preset sizes, plus the deck's current size if it's a custom value
  /// (e.g. set before this field became a dropdown), so editing an existing
  /// deck never silently changes its target size.
  List<int> get _sizeOptions {
    final sizes = {..._kSizePresets, _targetSize}.toList()..sort();
    return sizes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Give your deck a name first.');
      return;
    }

    final existing = widget.existingDeck;
    final deck = DeckData(
      id: existing?.id ?? 'deck-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      format: _format,
      targetSize: _targetSize,
      description: _descriptionController.text.trim(),
      cards: existing?.cards ?? const [],
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    Navigator.of(context).pop(DeckFormResult.saved(deck));
  }

  Future<void> _confirmDelete() async {
    final deck = widget.existingDeck!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete deck?'),
        content: Text(
          'This removes "${deck.name}" and its decklist. '
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
      Navigator.of(context).pop(const DeckFormResult.deleted());
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
                _isEditing ? 'Edit Deck' : 'Create a Deck',
                style: PokeBinderText.heading,
              ),
              const SizedBox(height: 4),
              Text(
                _isEditing
                    ? "Update the deck's details — its decklist stays put."
                    : 'Name it and set a target size — you can add cards '
                        'to it right after.',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),

              LabeledFormField(
                label: 'Deck name',
                child: TextField(
                  controller: _nameController,
                  decoration: pokeInputDecoration(
                    hint: 'e.g. Lightning Rush',
                    icon: Icons.style_outlined,
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
                  label: 'Format',
                  child: PokeDropdownField<DeckFormat>(
                    value: _format,
                    icon: Icons.flag_outlined,
                    options: [
                      for (final format in DeckFormat.values)
                        PokeDropdownOption(format, format.label, icon: format.icon),
                    ],
                    onChanged: (value) => setState(() => _format = value),
                  ),
                ),
                right: LabeledFormField(
                  label: 'Target deck size',
                  child: PokeDropdownField<int>(
                    value: _targetSize,
                    icon: Icons.format_list_numbered,
                    options: [
                      for (final size in _sizeOptions)
                        PokeDropdownOption(size, '$size Cards'),
                    ],
                    onChanged: (value) => setState(() => _targetSize = value),
                  ),
                ),
              ),

              LabeledFormField(
                label: 'Description (optional)',
                child: TextField(
                  controller: _descriptionController,
                  keyboardType: TextInputType.multiline,
                  minLines: 2,
                  maxLines: 5,
                  decoration: pokeInputDecoration(
                    hint: "What's the game plan for this deck?",
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
                      label: _isEditing ? 'Save Changes' : 'Create Deck',
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
                              'Delete Deck',
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