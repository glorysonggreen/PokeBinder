import 'package:flutter/material.dart';
import '../theme/pokebinder_theme.dart';

enum AppTab { home, binders, scan, decks, more }

extension AppTabMeta on AppTab {
  String get label {
    switch (this) {
      case AppTab.home:
        return 'Home';
      case AppTab.binders:
        return 'Binders';
      case AppTab.scan:
        return 'Scan';
      case AppTab.decks:
        return 'Decks';
      case AppTab.more:
        return 'More';
    }
  }

  IconData get icon {
    switch (this) {
      case AppTab.home:
        return Icons.home_outlined;
      case AppTab.binders:
        return Icons.menu_book_outlined;
      case AppTab.scan:
        return Icons.center_focus_strong_rounded;
      case AppTab.decks:
        return Icons.style_outlined;
      case AppTab.more:
        return Icons.grid_view_outlined;
    }
  }

  IconData get activeIcon {
    switch (this) {
      case AppTab.home:
        return Icons.home_rounded;
      case AppTab.binders:
        return Icons.menu_book_rounded;
      case AppTab.scan:
        return Icons.center_focus_strong_rounded;
      case AppTab.decks:
        return Icons.style_rounded;
      case AppTab.more:
        return Icons.grid_view_rounded;
    }
  }
}

class AppNavBar extends StatelessWidget {
  final AppTab current;
  final ValueChanged<AppTab> onChanged;

  const AppNavBar({super.key, required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        border: Border(
          top: BorderSide(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        ),
        boxShadow: [
          BoxShadow(
            color: PokeBinderColors.ink.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final tab in AppTab.values)
                tab == AppTab.scan
                    ? _ScanNavButton(
                        active: current == tab,
                        onTap: () => onChanged(tab),
                      )
                    : Expanded(
                        child: _NavItem(
                          tab: tab,
                          active: current == tab,
                          onTap: () => onChanged(tab),
                        ),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AppTab tab;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? PokeBinderColors.redDeep : PokeBinderColors.inkSoft;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? tab.activeIcon : tab.icon, size: 22, color: color),
              const SizedBox(height: 3),
              Text(
                tab.label,
                style: PokeBinderText.chipLabel.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: active ? 4 : 0,
                height: 4,
                decoration: const BoxDecoration(
                  color: PokeBinderColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanNavButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _ScanNavButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: Transform.translate(
        offset: const Offset(0, -12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: PokeBinderColors.redGradient,
                    border: Border.all(
                      color: active ? PokeBinderColors.gold : PokeBinderColors.cream,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: PokeBinderColors.redDeep.withValues(alpha: 0.5),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.center_focus_strong_rounded,
                    color: PokeBinderColors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Scan',
              style: PokeBinderText.chipLabel.copyWith(
                color: PokeBinderColors.redDeep,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
