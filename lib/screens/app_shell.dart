import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/app_nav_bar.dart';
import 'binders_screen.dart';
import 'home_screen.dart';
import 'scanner_screen.dart';

class AppShell extends StatefulWidget {
  final AppTab initialTab;

  const AppShell({super.key, this.initialTab = AppTab.binders});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late AppTab _tab = widget.initialTab;
  int _bindersLinkToken = 0;
  int _bindersInitialTabIndex = 0;
  String? _bindersInitialBinderId;

  void _switchTab(AppTab tab) => setState(() => _tab = tab);

  void _openBinders({int tabIndex = 0, String? binderId}) {
    setState(() {
      _bindersLinkToken++;
      _bindersInitialTabIndex = tabIndex;
      _bindersInitialBinderId = binderId;
      _tab = AppTab.binders;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: IndexedStack(
        index: AppTab.values.indexOf(_tab),
        children: [
          HomeScreen(
            onOpenAllCards: () => _openBinders(tabIndex: 1),
            onOpenBinders: () => _openBinders(tabIndex: 0),
            onOpenBinder: (BinderData binder) =>
                _openBinders(tabIndex: 0, binderId: binder.id),
            onOpenScan: () => _switchTab(AppTab.scan),
            onOpenMore: () => _switchTab(AppTab.more),
            onOpenDecks: () => _switchTab(AppTab.decks),
          ),
          BindersScreen(
            key: ValueKey(_bindersLinkToken),
            initialTabIndex: _bindersInitialTabIndex,
            initialBinderId: _bindersInitialBinderId,
          ),
          const ScannerScreen(),
          const _ComingSoonScreen(
            tab: AppTab.decks,
            title: 'Deck building',
            description:
                'Put together and manage your battle decks from your '
                'collection here.',
          ),
          const _ComingSoonScreen(
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