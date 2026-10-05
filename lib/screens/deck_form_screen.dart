import 'package:flutter/material.dart';
import '../models/deck_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';

const _kSizePresets = [15, 20, 30, 40, 60];

class DeckFormScreen extends StatefulWidget {
  const DeckFormScreen({super.key});

  @override
  State<DeckFormScreen> createState() => _DeckFormScreenState();
}

class _DeckFormScreenState extends State<DeckFormScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  DeckFormat _format = DeckFormat.standard;
  int _targetSize = 60;

  String? _nameError;

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

    Navigator.of(context).pop(
      DeckData(
        id: 'deck-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        format: _format,
        targetSize: _targetSize,
        description: _descriptionController.text.trim(),
        cards: const [],
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: PokeBinderSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackLink(
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('Create a Deck', style: PokeBinderText.heading),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text(
                'Name it and set a target size — you can add cards to it '
                'right after.',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),

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
                      label: 'Create Deck',
                      icon: Icons.add,
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
