import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/trainer_profile_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/app_nav_bar.dart';
import 'binders_screen.dart';
import 'decks_screen.dart';
import 'home_screen.dart';
import 'more_screen.dart';
import 'scanner_screen.dart';

class AppShell extends StatefulWidget {
  final AppTab initialTab;
  final String trainerName;

  const AppShell({
    super.key,
    this.initialTab = AppTab.home,
    this.trainerName = 'Ash',
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late AppTab _tab = widget.initialTab;
  late TrainerProfileData _profile =
      TrainerProfileData(name: widget.trainerName);
  int _bindersLinkToken = 0;
  int _bindersInitialTabIndex = 0;
  String? _bindersInitialBinderId;

  void _switchTab(AppTab tab) => setState(() => _tab = tab);

  void _handleProfileChanged(TrainerProfileData profile) =>
      setState(() => _profile = profile);

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
            profile: _profile,
            onProfileChanged: _handleProfileChanged,
            onOpenAllCards: () => _openBinders(tabIndex: 1),
            onOpenBinders: () => _openBinders(tabIndex: 0),
            onOpenBinder: (BinderData binder) =>
                _openBinders(tabIndex: 0, binderId: binder.id),
            onOpenScan: () => _switchTab(AppTab.scan),
            onOpenDecks: () => _switchTab(AppTab.decks),
          ),
          BindersScreen(
            key: ValueKey(_bindersLinkToken),
            initialTabIndex: _bindersInitialTabIndex,
            initialBinderId: _bindersInitialBinderId,
          ),
          const ScannerScreen(),
          const DecksScreen(),
          MoreScreen(
            profile: _profile,
            onProfileChanged: _handleProfileChanged,
            onOpenBinder: (BinderData binder) =>
                _openBinders(tabIndex: 0, binderId: binder.id),
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