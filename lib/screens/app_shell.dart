import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import '../models/trainer_profile_data.dart';
import '../models/wishlist_entry.dart';
import '../services/auth_service.dart';
import '../services/binder_repository.dart';
import '../services/card_repository.dart';
import '../services/deck_repository.dart';
import '../services/sync_status.dart';
import '../services/trainer_profile_repository.dart';
import '../services/wishlist_repository.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/app_nav_bar.dart';
import 'binders_screen.dart';
import 'decks_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  late AppTab _tab = widget.initialTab;
  late TrainerProfileData _profile =
      TrainerProfileData(name: widget.trainerName);
  bool _loading = true;
  String? _loadError;
  int _bindersLinkToken = 0;
  int _bindersInitialTabIndex = 0;
  String? _bindersInitialBinderId;
  int _decksLinkToken = 0;
  String? _decksInitialDeckId;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Every screen calls Repository.upsert/.delete without awaiting it, so
    // this is the one place a failed background save gets surfaced instead
    // of vanishing into an unhandled Future (see services/sync_status.dart).
    SyncStatus.lastError.addListener(_showSyncError);
  }

  @override
  void dispose() {
    SyncStatus.lastError.removeListener(_showSyncError);
    super.dispose();
  }

  void _showSyncError() {
    final message = SyncStatus.lastError.value;
    if (message == null) return;
    _scaffoldKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Pulls everything the app's screens read from `*.library` out of
  /// Supabase once, up front, so every screen below this one can keep
  /// assuming that data is already sitting in memory — exactly like it did
  /// before there was a backend.
  Future<void> _loadData() async {
    try {
      final profile =
          await TrainerProfileRepository.load(fallbackName: widget.trainerName);
      await Future.wait([
        BinderRepository.loadAll(),
        CardRepository.loadAll(),
        DeckRepository.loadAll(),
        WishlistRepository.loadAll(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = "Couldn't load your collection — check your connection "
            'and try again.';
      });
    }
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    // Clear cached data so the next person to sign in on this device
    // doesn't briefly see the previous account's collection.
    BinderData.library.clear();
    PokemonCardData.library.clear();
    DeckData.library.clear();
    WishlistEntry.library.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _switchTab(AppTab tab) => setState(() => _tab = tab);

  void _handleProfileChanged(TrainerProfileData profile) {
    setState(() => _profile = profile);
    TrainerProfileRepository.upsert(profile);
  }

  void _openBinders({int tabIndex = 0, String? binderId}) {
    setState(() {
      _bindersLinkToken++;
      _bindersInitialTabIndex = tabIndex;
      _bindersInitialBinderId = binderId;
      _tab = AppTab.binders;
    });
  }

  /// Switches to the Decks tab and opens [deck] there. Bumping the token
  /// rebuilds DecksScreen so it picks up the new deck and jumps to it.
  void _openDeck(DeckData deck) {
    setState(() {
      _decksLinkToken++;
      _decksInitialDeckId = deck.id;
      _tab = AppTab.decks;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: PokeBinderColors.cream,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        backgroundColor: PokeBinderColors.cream,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(PokeBinderSpacing.sp5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: PokeBinderSpacing.sp3),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _loadError = null;
                    });
                    _loadData();
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        backgroundColor: PokeBinderColors.cream,
        body: FadeIndexedStack(
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
              onOpenDeck: _openDeck,
            ),
            BindersScreen(
              key: ValueKey(_bindersLinkToken),
              initialTabIndex: _bindersInitialTabIndex,
              initialBinderId: _bindersInitialBinderId,
            ),
            const ScannerScreen(),
            DecksScreen(
              key: ValueKey(_decksLinkToken),
              initialDeckId: _decksInitialDeckId,
            ),
            MoreScreen(
              profile: _profile,
              onProfileChanged: _handleProfileChanged,
              onOpenBinder: (BinderData binder) =>
                  _openBinders(tabIndex: 0, binderId: binder.id),
              onSignOut: _signOut,
            ),
          ],
        ),
        bottomNavigationBar: AppNavBar(
          current: _tab,
          onChanged: (tab) => setState(() => _tab = tab),
        ),
      ),
    );
  }
}