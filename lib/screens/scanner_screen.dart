import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import 'card_details_screen.dart';
import 'card_form_screen.dart';

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

  bool _scanning = false;
  PokemonCardData? _lastScan = PokemonCardData.sample;

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

    final result = PokemonCardData.sample;
    setState(() {
      _scanning = false;
      _lastScan = result;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Found ${result.name} — review it below.')),
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

  void _viewLastScan() {
    final card = _lastScan;
    if (card == null) return;
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

  void _addLastScan() {
    final card = _lastScan;
    if (card == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardFormScreen(
          existingCard: card,
          binders: _binders,
          defaultBinderId: _binders.first.id,
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
                    Text(
                      _scanning ? 'Scanning…' : 'Align card within frame',
                      style: PokeBinderText.chakraPetch(const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                        color: PokeBinderColors.inkSoft,
                      )),
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
                child: InkWell(
                  onTap: _openManualEntry,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_outlined,
                            size: 13, color: PokeBinderColors.inkSoft),
                        const SizedBox(width: 5),
                        Text(
                          'Or enter card details manually',
                          style: PokeBinderText.chakraPetch(const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: PokeBinderColors.inkSoft,
                          )),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp5),

              if (_lastScan != null) ...[
                Text('LAST SCAN RESULT', style: PokeBinderText.sectionLabel),
                const SizedBox(height: PokeBinderSpacing.sp2),
                _LastScanPanel(
                  card: _lastScan!,
                  onTap: _viewLastScan,
                  onAdd: _addLastScan,
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
    return Container(
      width: 190,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C2A2C), Color(0xFF0C1517)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 5 / 7,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: PokeBinderColors.gold.withValues(alpha: 0.75),
                    width: 2,
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
                    padding: const EdgeInsets.symmetric(horizontal: 4),
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
                            color: PokeBinderColors.gold.withValues(alpha: 0.7),
                            blurRadius: 8,
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
                    borderRadius: BorderRadius.circular(10),
                    color: PokeBinderColors.gold.withValues(alpha: 0.08),
                  ),
                ),
              ),
          ],
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
        width: 16,
        height: 16,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: scanning ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
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
                      color: PokeBinderColors.red.withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 9),
                    ),
                  ],
                  border: Border.all(
                    color: PokeBinderColors.white.withValues(alpha: 0.6),
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
              if (scanning)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: PokeBinderColors.ink,
                  ),
                )
              else
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

class _LastScanPanel extends StatelessWidget {
  final PokemonCardData card;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _LastScanPanel({
    required this.card,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PokeBinderColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: PokeBinderColors.ink.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 40,
                  height: 56,
                  child: card.imageAssetPath != null
                      ? Image.asset(card.imageAssetPath!, fit: BoxFit.cover)
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: card.type.gradientColors,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: PokeBinderColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${card.setName} · #${card.cardNumber} · ${card.rarity}',
                      style: PokeBinderText.listRowSubtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp2),
              _AddTag(onTap: onAdd),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTag extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTag({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [PokeBinderColors.gold, PokeBinderColors.goldDeep],
            ),
            boxShadow: [
              BoxShadow(
                color: PokeBinderColors.goldDeep.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'Add',
            style: PokeBinderText.chakraPetch(const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: PokeBinderColors.white,
            )),
          ),
        ),
      ),
    );
  }
}
