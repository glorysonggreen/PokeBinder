import 'package:flutter/material.dart';
import '../models/wishlist_entry.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';

class WishlistFormResult {
  final WishlistEntry? entry;
  final bool deleted;

  const WishlistFormResult.saved(WishlistEntry entry)
      : entry = entry,
        deleted = false;

  const WishlistFormResult.deleted()
      : entry = null,
        deleted = true;
}

class WishlistFormScreen extends StatefulWidget {
  final WishlistEntry? existingEntry;
  final WishlistEntryKind initialKind;

  const WishlistFormScreen({
    super.key,
    this.existingEntry,
    this.initialKind = WishlistEntryKind.wishlist,
  });

  @override
  State<WishlistFormScreen> createState() => _WishlistFormScreenState();
}

class _WishlistFormScreenState extends State<WishlistFormScreen> {
  late final _nameController =
      TextEditingController(text: widget.existingEntry?.name ?? '');
  late final _setController =
      TextEditingController(text: widget.existingEntry?.setName ?? '');
  late final _qtyController = TextEditingController(
    text: '${widget.existingEntry?.quantity ?? 1}',
  );
  late final _notesController =
      TextEditingController(text: widget.existingEntry?.notes ?? '');

  late WishlistEntryKind _kind =
      widget.existingEntry?.kind ?? widget.initialKind;

  String? _nameError;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void dispose() {
    _nameController.dispose();
    _setController.dispose();
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Give the card a name first.');
      return;
    }

    final qty = int.tryParse(_qtyController.text) ?? 1;

    final entry = WishlistEntry(
      id: widget.existingEntry?.id ??
          'wishlist-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      setName: _setController.text.trim(),
      quantity: qty < 1 ? 1 : qty,
      notes: _notesController.text.trim(),
      kind: _kind,
      dateAdded: widget.existingEntry?.dateAdded ?? DateTime.now(),
    );

    Navigator.of(context).pop(WishlistFormResult.saved(entry));
  }

  void _delete() {
    Navigator.of(context).pop(const WishlistFormResult.deleted());
  }

  @override
  Widget build(BuildContext context) {
    final isWishlist = _kind == WishlistEntryKind.wishlist;

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
                label: '‹ Wishlist',
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('WISHLIST & TRADE', style: PokeBinderText.eyebrow),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text(
                _isEditing
                    ? 'Edit entry'
                    : (isWishlist ? 'Add to wishlist' : 'Add to trade list'),
                style: PokeBinderText.heading,
              ),
              const SizedBox(height: 4),
              Text(
                isWishlist
                    ? "Track a card you're hoping to pull or pick up."
                    : "List a card you're ready to trade away.",
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),

              SegmentedTabBar(
                index: isWishlist ? 0 : 1,
                labels: const ['Wishlist', 'Trade list'],
                onChanged: (i) => setState(
                  () => _kind = i == 0
                      ? WishlistEntryKind.wishlist
                      : WishlistEntryKind.trade,
                ),
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
                  label: 'Set (optional)',
                  child: TextField(
                    controller: _setController,
                    decoration: pokeInputDecoration(
                      hint: 'Base Set',
                      icon: Icons.collections_bookmark_outlined,
                    ),
                  ),
                ),
                right: LabeledFormField(
                  label: 'Quantity',
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: pokeInputDecoration(icon: Icons.style_outlined),
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
                      label: _isEditing ? 'Save Changes' : 'Add',
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
                      onTap: _delete,
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
            ],
          ),
        ),
      ),
    );
  }
}
