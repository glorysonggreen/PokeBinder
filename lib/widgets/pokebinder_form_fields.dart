import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/pokebinder_theme.dart';
import 'pokebinder_controls.dart';

InputDecoration pokeInputDecoration({
  String? hint,
  IconData? icon,
  Widget? suffixIcon,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  );

  return InputDecoration(
    hintText: hint,
    hintStyle: PokeBinderText.hint,
    filled: true,
    fillColor: PokeBinderColors.white,
    isDense: true,
    prefixIcon: icon != null
        ? Icon(icon, size: 16, color: PokeBinderColors.redDeep.withValues(alpha: 0.55))
        : null,
    prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 0),
    suffixIcon: suffixIcon,
    suffixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 0),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: PokeBinderSpacing.sp3,
      vertical: PokeBinderSpacing.sp4,
    ),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: PokeBinderColors.red.withValues(alpha: 0.55),
        width: 1.5,
      ),
    ),
  );
}

class LabeledFormField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabeledFormField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp2),
            child: Text(label.toUpperCase(), style: PokeBinderText.formLabel),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: PokeBinderColors.ink.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class FormFieldRow extends StatelessWidget {
  final Widget left;
  final Widget right;

  const FormFieldRow({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: PokeBinderSpacing.sp2),
        Expanded(child: right),
      ],
    );
  }
}

class PokeDropdownOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  final String? subtitle;

  final String? group;

  const PokeDropdownOption(
    this.value,
    this.label, {
    this.icon,
    this.subtitle,
    this.group,
  });
}

class PokeDropdownField<T> extends StatelessWidget {
  final T value;
  final List<PokeDropdownOption<T>> options;
  final ValueChanged<T> onChanged;
  final IconData? icon;

  final double? height;

  const PokeDropdownField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final selected =
        options.firstWhere((o) => o.value == value, orElse: () => options.first);
    final displayIcon = selected.icon ?? icon;

    return LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth = constraints.maxWidth.isFinite
            ? math.max(constraints.maxWidth, 170.0)
            : 190.0;

        return Theme(
          data: Theme.of(context).copyWith(
            highlightColor: PokeBinderColors.red.withValues(alpha: 0.06),
            splashColor: PokeBinderColors.red.withValues(alpha: 0.06),
            hoverColor: PokeBinderColors.red.withValues(alpha: 0.05),
          ),
          child: PopupMenuButton<T>(
            initialValue: value,
            onSelected: onChanged,
            offset: const Offset(0, 50),
            color: PokeBinderColors.white,
            elevation: 8,
            shadowColor: PokeBinderColors.ink.withValues(alpha: 0.2),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
            ),
            constraints: BoxConstraints(minWidth: menuWidth),
            padding: const EdgeInsets.symmetric(
              vertical: PokeBinderSpacing.sp2,
            ),
            itemBuilder: (context) => [
              for (final option in options)
                PopupMenuItem<T>(
                  value: option.value,
                  height: 38,
                  padding: const EdgeInsets.symmetric(
                    horizontal: PokeBinderSpacing.sp1,
                  ),
                  child: _PokeDropdownMenuRow(
                    label: option.label,
                    icon: option.icon,
                    selected: option.value == value,
                  ),
                ),
            ],
            child: _PokeDropdownBox(
              label: selected.label,
              icon: displayIcon,
              height: height,
            ),
          ),
        );
      },
    );
  }
}

class _PokeDropdownBox extends StatelessWidget {
  final String label;
  final IconData? icon;
  final double? height;

  const _PokeDropdownBox({required this.label, this.icon, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      alignment: height == null ? null : Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: PokeBinderSpacing.sp3,
        vertical: height == null ? PokeBinderSpacing.sp4 : 0,
      ),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 16,
                color: PokeBinderColors.redDeep.withValues(alpha: 0.55)),
            const SizedBox(width: PokeBinderSpacing.sp2),
          ],
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: PokeBinderText.selectValue,
            ),
          ),
          const Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: PokeBinderColors.inkSoft,
          ),
        ],
      ),
    );
  }
}

class PokeSearchableDropdownField<T> extends StatelessWidget {
  final T value;
  final List<PokeDropdownOption<T>> options;
  final ValueChanged<T> onChanged;
  final IconData? icon;

  final String title;

  final String searchHint;

  final String noMatchesTitle;

  const PokeSearchableDropdownField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.title,
    this.searchHint = 'Search',
    this.noMatchesTitle = 'No matches found.',
    this.icon,
  });

  static const _sheetHeightFactor = 0.85;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<PokeDropdownOption<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: PokeBinderColors.cream,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * _sheetHeightFactor,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SearchableOptionsSheet<T>(
        title: title,
        searchHint: searchHint,
        noMatchesTitle: noMatchesTitle,
        options: options,
        value: value,
      ),
    );
    if (picked != null) onChanged(picked.value);
  }

  @override
  Widget build(BuildContext context) {
    final selected =
        options.firstWhere((o) => o.value == value, orElse: () => options.first);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _open(context),
      child: _PokeDropdownBox(label: selected.label, icon: selected.icon ?? icon),
    );
  }
}

class _SearchableOptionsSheet<T> extends StatefulWidget {
  final String title;
  final String searchHint;
  final String noMatchesTitle;
  final List<PokeDropdownOption<T>> options;
  final T value;

  const _SearchableOptionsSheet({
    required this.title,
    required this.searchHint,
    required this.noMatchesTitle,
    required this.options,
    required this.value,
  });

  @override
  State<_SearchableOptionsSheet<T>> createState() =>
      _SearchableOptionsSheetState<T>();
}

class _SearchableOptionsSheetState<T> extends State<_SearchableOptionsSheet<T>> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<PokeDropdownOption<T>> _matches() {
    final needle = _controller.text.trim().toLowerCase();
    if (needle.isEmpty) return widget.options;
    return widget.options
        .where((o) =>
            o.label.toLowerCase().contains(needle) ||
            (o.group?.toLowerCase().contains(needle) ?? false))
        .toList();
  }

  List<Object> _rows(List<PokeDropdownOption<T>> matches) {
    final groups = <String?, List<PokeDropdownOption<T>>>{};
    for (final option in matches) {
      (groups[option.group] ??= []).add(option);
    }
    return [
      for (final entry in groups.entries) ...[
        if (entry.key != null) entry.key!,
        ...entry.value,
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches();
    final rows = _rows(matches);
    final searching = _controller.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PokeBinderSpacing.sp4,
              0,
              PokeBinderSpacing.sp2,
              PokeBinderSpacing.sp2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.title, style: PokeBinderText.headingSm),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded,
                      color: PokeBinderColors.inkSoft),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PokeBinderSpacing.sp4),
            child: CollectionSearchBar(
              hint: widget.searchHint,
              controller: _controller,
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PokeBinderSpacing.sp4,
                PokeBinderSpacing.sp3,
                PokeBinderSpacing.sp4,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${matches.length} ${matches.length == 1 ? 'MATCH' : 'MATCHES'}',
                  style: PokeBinderText.resultCount,
                ),
              ),
            ),
          const SizedBox(height: PokeBinderSpacing.sp2),
          Expanded(
            child: matches.isEmpty
                ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PokeBinderSpacing.sp4,
                    ),
                    child: EmptyFilterState(
                      title: widget.noMatchesTitle,
                      subtitle: 'Check the spelling or try a shorter search.',
                      clearFiltersLabel: 'Clear search',
                      onClearFilters: () => setState(_controller.clear),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      PokeBinderSpacing.sp2,
                      0,
                      PokeBinderSpacing.sp2,
                      PokeBinderSpacing.sp4,
                    ),
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final row = rows[i];
                      if (row is String) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(
                            PokeBinderSpacing.sp2,
                            PokeBinderSpacing.sp4,
                            PokeBinderSpacing.sp2,
                            PokeBinderSpacing.sp1,
                          ),
                          child: Text(row.toUpperCase(),
                              style: PokeBinderText.sectionLabel),
                        );
                      }
                      final option = row as PokeDropdownOption<T>;
                      return InkWell(
                        borderRadius: BorderRadius.circular(9),
                        onTap: () => Navigator.of(context).pop(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: PokeBinderSpacing.sp1,
                          ),
                          child: _PokeDropdownMenuRow(
                            label: option.label,
                            icon: option.icon,
                            subtitle: option.subtitle,
                            selected: option.value == widget.value,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PokeDropdownMenuRow extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? subtitle;
  final bool selected;

  const _PokeDropdownMenuRow({
    required this.label,
    this.icon,
    this.subtitle,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PokeBinderSpacing.sp2,
        vertical: PokeBinderSpacing.sp2,
      ),
      decoration: BoxDecoration(
        color: selected ? PokeBinderColors.red.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 15,
                color: selected
                    ? PokeBinderColors.redDeep
                    : PokeBinderColors.inkSoft),
            const SizedBox(width: PokeBinderSpacing.sp2),
          ],
          Expanded(
            child: Text(
              label,
              style: PokeBinderText.pillLabel(selected: selected),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: PokeBinderSpacing.sp2),
            Text(subtitle!, style: PokeBinderText.listRowSubtitle),
          ],
          if (selected)
            const Padding(
              padding: EdgeInsets.only(left: PokeBinderSpacing.sp1),
              child: Icon(
                Icons.check_rounded,
                size: 15,
                color: PokeBinderColors.red,
              ),
            ),
        ],
      ),
    );
  }
}
