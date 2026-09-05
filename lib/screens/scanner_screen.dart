import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokemon_card_widget.dart';
import 'card_details_screen.dart';
import 'card_form_screen.dart';

class _ScanEntry {
  final PokemonCardData card;
  final DateTime scannedAt;

  const _ScanEntry({required this.card, required this.scannedAt});
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  static const _kMaxRecentScans = 3;

  late final List<PokemonCardData> _demoPool = [
    'Charizard',
    'Gyarados',
    'Mewtwo',
    'Pikachu',
    'Blastoise',
    'Alakazam',
    'Vaporeon',
  ].map((name) => PokemonCardData.library.firstWhere((c) => c.name == name)).toList();
  int _demoIndex = 0;

  bool _scanning = false;

  late final List<_ScanEntry> _recentScans = [
    _ScanEntry(
      card: PokemonCardData.sample,
      scannedAt: DateTime.now().subtract(const Duration(minutes: 6)),
    ),
    _ScanEntry(
      card: PokemonCardData.library.firstWhere((c) => c.name == 'Pikachu'),
      scannedAt: DateTime.now().subtract(const Duration(minutes: 19)),
    ),
    _ScanEntry(
      card: PokemonCardData.library.firstWhere((c) => c.name == 'Blastoise'),
      scannedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  final List<BinderData> _binders = BinderData.sampleBinders;

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_scanning) return;
    setState(() => _scanning = true);

    await Future.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;

    final detected = _demoPool[_demoIndex % _demoPool.length];
    _demoIndex++;

    setState(() => _scanning = false);

    final result = await Navigator.of(context).push<CardFormResult>(
      MaterialPageRoute(
        builder: (_) => CardFormScreen(
          scannedCard: detected,
          binders: _binders,
          defaultBinderId: _binders.first.id,
        ),
      ),
    );
    if (!mounted || result == null || result.deleted) return;

    final confirmed = result.card!;
    setState(() {
      _recentScans.insert(0, _ScanEntry(card: confirmed, scannedAt: DateTime.now()));
      if (_recentScans.length > _kMaxRecentScans) {
        _recentScans.removeRange(_kMaxRecentScans, _recentScans.length);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${confirmed.name} to your collection.')),
    );
  }

  void _openManualEntry() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardFormScreen(
          binders: _binders,
          defaultBinderId: _binders.first.id,
        ),
      ),
    );
  }

  void _viewScan(PokemonCardData card) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardDetailsScreen(
          card: card,
          binders: _binders,
          onSave: (_, __) {},
        ),
      ),
    );
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
              Text('CARD SCANNER', style: PokeBinderText.eyebrow),
              const SizedBox(height: 2),
              Text('Scan a card', style: PokeBinderText.heading),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text(
                'Line the card up in the frame and tap to capture.',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp5),

              Center(
                child: Column(
                  children: [
                    _Viewfinder(sweep: _sweep, scanning: _scanning),
                    const SizedBox(height: PokeBinderSpacing.sp3),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        _scanning ? 'Scanning…' : 'Align Card Within Frame',
                        key: ValueKey(_scanning),
                        style: PokeBinderText.chakraPetch(TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.4,
                          color: _scanning
                              ? PokeBinderColors.redDeep
                              : PokeBinderColors.inkSoft,
                        )),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp5),

              Center(
                child: Column(
                  children: [
                    _CaptureButton(scanning: _scanning, onTap: _capture),
                    const SizedBox(height: PokeBinderSpacing.sp2),
                    Text(
                      'TAP TO CAPTURE',
                      style: PokeBinderText.chakraPetch(const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.6,
                        color: PokeBinderColors.redDeep,
                      )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),

              Center(
                child: _GhostLinkButton(
                  icon: Icons.edit_outlined,
                  label: 'Or Enter Card Details Manually',
                  onTap: _openManualEntry,
                ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp5),

              if (_recentScans.isNotEmpty) ...[
                Row(
                  children: [
                    Text('RECENT SCANS', style: PokeBinderText.sectionLabel),
                    const SizedBox(width: PokeBinderSpacing.sp2),
                    Expanded(
                      child: Divider(
                        color: PokeBinderColors.ink.withValues(alpha: 0.08),
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PokeBinderSpacing.sp2),
                _RecentScansPanel(
                  scans: _recentScans,
                  onTapScan: _viewScan,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  final AnimationController sweep;
  final bool scanning;

  const _Viewfinder({required this.sweep, required this.scanning});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 230,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF223234), Color(0xFF0C1517)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          if (scanning)
            BoxShadow(
              color: PokeBinderColors.gold.withValues(alpha: 0.25),
              blurRadius: 26,
              spreadRadius: 1,
            ),
        ],
        border: Border.all(
          color: PokeBinderColors.gold.withValues(alpha: scanning ? 0.3 : 0.12),
        ),
      ),
      child: AspectRatio(
        aspectRatio: kPokemonCardImageAspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.2),
                      radius: 1.1,
                      colors: [Color(0x1AFFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: PokeBinderColors.gold.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              for (final alignment in const [
                Alignment.topLeft,
                Alignment.topRight,
                Alignment.bottomLeft,
                Alignment.bottomRight,
              ])
                _Corner(alignment: alignment),
              AnimatedBuilder(
                animation: sweep,
                builder: (context, child) {
                  final y = -1 + 2 * sweep.value;
                  return Align(
                    alignment: Alignment(0, y),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        width: double.infinity,
                        height: 2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              PokeBinderColors.gold.withValues(alpha: 0),
                              PokeBinderColors.gold,
                              PokeBinderColors.gold.withValues(alpha: 0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: PokeBinderColors.gold.withValues(alpha: 0.75),
                              blurRadius: 9,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (scanning)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: PokeBinderColors.gold.withValues(alpha: 0.06),
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

class _Corner extends StatelessWidget {
  final Alignment alignment;

  const _Corner({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    const side = BorderSide(color: PokeBinderColors.gold, width: 3);

    return Align(
      alignment: alignment,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? side : BorderSide.none,
            bottom: !isTop ? side : BorderSide.none,
            left: isLeft ? side : BorderSide.none,
            right: !isLeft ? side : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(6) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(6) : Radius.zero,
            bottomLeft: !isTop && isLeft ? const Radius.circular(6) : Radius.zero,
            bottomRight: !isTop && !isLeft ? const Radius.circular(6) : Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
              color: PokeBinderColors.gold.withValues(alpha: 0.55),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final bool scanning;
  final VoidCallback onTap;

  const _CaptureButton({required this.scanning, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PokeBinderColors.red.withValues(alpha: scanning ? 0.16 : 0.08),
            ),
          ),
          AnimatedScale(
            scale: scanning ? 0.94 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PokeBinderColors.cream,
                          boxShadow: [
                            BoxShadow(
                              color: PokeBinderColors.redDeep,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: PokeBinderColors.red.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 9),
                            ),
                          ],
                          border: Border.all(
                            color: PokeBinderColors.white.withValues(alpha: 0.7),
                            width: 2,
                          ),
                        ),
                      ),
                      ClipPath(
                        clipper: _TopHalfClipper(),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFEC5138), PokeBinderColors.red],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 9,
                        left: 14,
                        child: Container(
                          width: 16,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.55),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 6,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [PokeBinderColors.ink, Color(0xFF100D0B)],
                          ),
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PokeBinderColors.white,
                          border: Border.all(color: PokeBinderColors.ink, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: PokeBinderColors.white.withValues(alpha: 0.55),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (scanning)
            IgnorePointer(
              child: SizedBox(
                width: 78,
                height: 78,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: PokeBinderColors.gold.withValues(alpha: 0.85),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopHalfClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.52));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _GhostLinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GhostLinkButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PokeBinderColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PokeBinderColors.red.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: PokeBinderColors.redDeep.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text(
                label,
                style: PokeBinderText.chakraPetch(const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: PokeBinderColors.redDeep,
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentScansPanel extends StatelessWidget {
  final List<_ScanEntry> scans;
  final ValueChanged<PokemonCardData> onTapScan;

  const _RecentScansPanel({required this.scans, required this.onTapScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        boxShadow: kCardElevation,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          children: [
            for (var i = 0; i < scans.length; i++) ...[
              if (i != 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 114,
                  color: PokeBinderColors.ink.withValues(alpha: 0.06),
                ),
              _ScanRow(
                entry: scans[i],
                isNewest: i == 0,
                onTap: () => onTapScan(scans[i].card),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card row for a recent scan, styled to match [_DeckCardEntryRow] on the
/// Deck Details screen: same thumbnail size/frame, chakraPetch bold name,
/// `set · #number` subtitle line, and a [Wrap] of small icon+label tags
/// (rarity, condition). The newest-scan dot and the relative-time badge
/// replace the deck row's quantity badge, since scans don't carry a
/// quantity of their own.
class _ScanRow extends StatelessWidget {
  final _ScanEntry entry;
  final bool isNewest;
  final VoidCallback onTap;

  const _ScanRow({
    required this.entry,
    required this.isNewest,
    required this.onTap,
  });

  String get _relativeTime {
    final diff = DateTime.now().difference(entry.scannedAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final card = entry.card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 14, 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: PokeBinderColors.ink.withValues(alpha: 0.08),
                      ),
                      boxShadow: kCardElevation,
                    ),
                    child: CardThumbnail(
                      card: card,
                      width: 92,
                      height: 127,
                      borderRadius: 5,
                    ),
                  ),
                  if (isNewest)
                    Positioned(
                      top: -4,
                      left: -4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PokeBinderColors.gold,
                          border: Border.all(color: PokeBinderColors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: PokeBinderColors.gold.withValues(alpha: 0.7),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: PokeBinderSpacing.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      style: PokeBinderText.chakraPetch(const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: PokeBinderColors.ink,
                      )),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${card.setName} · #${card.cardNumber}',
                      style: PokeBinderText.listRowSubtitle,
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _RarityTag(rarity: card.rarity),
                        _ConditionTag(code: card.condition),
                      ],
                    ),
                    if (card.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        card.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: PokeBinderText.listRowSubtitle.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ScanTimeBadge(label: _relativeTime),
                  const SizedBox(height: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: PokeBinderColors.inkSoft,
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

/// Small icon + label pairing for a card's rarity, matching the tag used
/// on the Deck Details card rows (same [rarityIconFor] lookup).
class _RarityTag extends StatelessWidget {
  final String rarity;

  const _RarityTag({required this.rarity});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(rarityIconFor(rarity), size: 11, color: PokeBinderColors.goldDeep),
        const SizedBox(width: 4),
        Text(rarity, style: PokeBinderText.listRowSubtitle),
      ],
    );
  }
}

/// Small icon + label pairing for a card's condition, matching the tag
/// used on the Deck Details card rows (same [conditionIconFor] lookup and
/// [kConditionOptions] label expansion).
class _ConditionTag extends StatelessWidget {
  final String code;

  const _ConditionTag({required this.code});

  @override
  Widget build(BuildContext context) {
    final label = kConditionOptions
        .firstWhere((c) => c.$2 == code, orElse: () => (code, code))
        .$1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(conditionIconFor(code), size: 11, color: PokeBinderColors.teal),
        const SizedBox(width: 4),
        Text(label, style: PokeBinderText.listRowSubtitle),
      ],
    );
  }
}

/// Pill-shaped time badge, styled the same way as the Deck Details
/// quantity badge (tinted background + bold colored label) but showing
/// how long ago the card was scanned instead of a quantity.
class _ScanTimeBadge extends StatelessWidget {
  final String label;

  const _ScanTimeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: PokeBinderColors.inkSoft.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: PokeBinderText.chakraPetch(const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: PokeBinderColors.inkSoft,
        )),
      ),
    );
  }
}