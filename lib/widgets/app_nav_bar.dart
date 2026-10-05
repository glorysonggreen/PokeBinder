import 'package:flutter/material.dart';
import '../theme/pokebinder_motion.dart';
import '../theme/pokebinder_theme.dart';
import 'motion_widgets.dart';
import '../services/audio_service.dart';

enum AppTab { home, binders, add, decks, more }

extension AppTabMeta on AppTab {
  String get label {
    switch (this) {
      case AppTab.home:
        return 'Home';
      case AppTab.binders:
        return 'Binders';
      case AppTab.add:
        return 'Add';
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
      case AppTab.add:
        return Icons.add_rounded;
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
      case AppTab.add:
        return Icons.add_rounded;
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
                tab == AppTab.add
                    ? _AddNavButton(
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
          padding: const EdgeInsets.symmetric(vertical: PokeBinderSpacing.sp2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BouncySwitcher(
                child: Icon(
                  active ? tab.activeIcon : tab.icon,
                  key: ValueKey(active),
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp1),
              AnimatedDefaultTextStyle(
                duration: PokeBinderMotion.fast,
                style: PokeBinderText.chipLabel.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.bold : FontWeight.w600,
                ),
                child: Text(tab.label),
              ),
              const SizedBox(height: PokeBinderSpacing.sp0),
              AnimatedContainer(
                duration: PokeBinderMotion.pop,
                curve: PokeBinderMotion.smooth,
                width: active ? 16 : 0,
                height: 4,
                decoration: BoxDecoration(
                  color: PokeBinderColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddNavButton extends StatefulWidget {
  final bool active;
  final VoidCallback onTap;

  const _AddNavButton({required this.active, required this.onTap});

  @override
  State<_AddNavButton> createState() => _AddNavButtonState();
}

class _AddNavButtonState extends State<_AddNavButton> {
  bool _pressed = false;

  double _turns = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: Transform.translate(
        offset: const Offset(0, -12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: _pressed ? 0.88 : 1,
              duration: PokeBinderMotion.adapt(
                context,
                _pressed ? PokeBinderMotion.press : PokeBinderMotion.release,
              ),
              curve:
                  _pressed ? PokeBinderMotion.curve : PokeBinderMotion.spring,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () {
                    setState(() => _turns += 1);
                    PokeBinderAudio.play(Sfx.addPress);
                    widget.onTap();
                  },
                  onHighlightChanged: (value) {
                    if (mounted) setState(() => _pressed = value);
                  },
                  customBorder: const CircleBorder(),
                  child: AnimatedContainer(
                    duration: PokeBinderMotion.fast,
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: PokeBinderColors.redGradient,
                      border: Border.all(
                        color: widget.active
                            ? PokeBinderColors.gold
                            : PokeBinderColors.cream,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              PokeBinderColors.redDeep.withValues(alpha: 0.5),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: AnimatedRotation(
                      turns: _turns,
                      duration: PokeBinderMotion.adapt(
                        context,
                        const Duration(milliseconds: 600),
                      ),
                      curve: PokeBinderMotion.bounce,
                      child: const Icon(
                        Icons.add_rounded,
                        color: PokeBinderColors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: PokeBinderSpacing.sp1),
            Text(
              'Add',
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
