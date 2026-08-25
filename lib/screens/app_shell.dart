import 'package:flutter/material.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/app_nav_bar.dart';
import 'binders_screen.dart';
import 'scanner_screen.dart';

class AppShell extends StatefulWidget {
  final AppTab initialTab;

  const AppShell({super.key, this.initialTab = AppTab.binders});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late AppTab _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: IndexedStack(
        index: AppTab.values.indexOf(_tab),
        children: const [
          _ComingSoonScreen(
            tab: AppTab.home,
            title: 'Your Pokédex home',
            description:
                'A quick-glance dashboard — recent pulls, collection value, '
                'and shortcuts to your binders — lands here next.',
          ),
          BindersScreen(),
          ScannerScreen(),
          _ComingSoonScreen(
            tab: AppTab.decks,
            title: 'Deck building',
            description:
                'Put together and manage your battle decks from your '
                'collection here.',
          ),
          _ComingSoonScreen(
            tab: AppTab.more,
            title: 'More',
            description:
                'Trainer profile, wishlist, trade list, stats, and settings '
                'will live here.',
          ),
        ],
      ),
      bottomNavigationBar: AppNavBar(
        current: _tab,
        onChanged: (tab) => setState(() => _tab = tab),
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  final AppTab tab;
  final String title;
  final String description;

  const _ComingSoonScreen({
    required this.tab,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PokeBinderSpacing.sp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tab.label.toUpperCase(), style: PokeBinderText.eyebrow),
              const SizedBox(height: PokeBinderSpacing.sp3),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PokeBinderColors.red.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          tab.activeIcon,
                          size: 30,
                          color: PokeBinderColors.redDeep,
                        ),
                      ),
                      const SizedBox(height: PokeBinderSpacing.sp4),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: PokeBinderText.heading,
                      ),
                      const SizedBox(height: PokeBinderSpacing.sp2),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: Text(
                          description,
                          textAlign: TextAlign.center,
                          style: PokeBinderText.subtitle,
                        ),
                      ),
                      const SizedBox(height: PokeBinderSpacing.sp2),
                      Text(
                        'Coming soon',
                        style: PokeBinderText.chakraPetch(const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: PokeBinderColors.goldDeep,
                        )),
                      ),
                    ],
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
