import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../theme/pokebinder_theme.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'trainer_card_screen.dart';
import 'wishlist_screen.dart';

class MoreScreen extends StatefulWidget {
  final VoidCallback? onOpenStats;
  final VoidCallback? onOpenWishlist;
  final VoidCallback? onOpenSettings;
  final ValueChanged<BinderData>? onOpenBinder;
  final bool initialShowTrainerCard;

  const MoreScreen({
    super.key,
    this.onOpenStats,
    this.onOpenWishlist,
    this.onOpenSettings,
    this.onOpenBinder,
    this.initialShowTrainerCard = false,
  });

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  late bool _showingTrainerCard = widget.initialShowTrainerCard;

  @override
  Widget build(BuildContext context) {
    if (_showingTrainerCard) {
      return TrainerCardScreen(
        onBack: () => setState(() => _showingTrainerCard = false),
        onOpenBinder: widget.onOpenBinder,
      );
    }

    final rows = [
      _MoreRowData(
        icon: Icons.badge_rounded,
        gradient: PokeBinderColors.redGradient,
        title: 'Trainer Card',
        subtitle: 'Profile, badges, favorite deck',
        onTap: () => setState(() => _showingTrainerCard = true),
      ),
      _MoreRowData(
        icon: Icons.bar_chart_rounded,
        gradient: PokeBinderColors.goldGradient,
        title: 'Collection Statistics',
        subtitle: 'Value, rarity, set breakdown',
        onTap: () {
          if (widget.onOpenStats != null) {
            widget.onOpenStats!();
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StatsScreen()),
          );
        },
      ),
      _MoreRowData(
        icon: Icons.swap_horiz_rounded,
        gradient: PokeBinderColors.tealGradient,
        title: 'Wishlist & Trade List',
        subtitle: 'Cards you want or will trade',
        onTap: () {
          if (widget.onOpenWishlist != null) {
            widget.onOpenWishlist!();
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WishlistScreen()),
          );
        },
      ),
      _MoreRowData(
        icon: Icons.settings_rounded,
        gradient: PokeBinderColors.slateGradient,
        title: 'Settings',
        subtitle: 'Account, backup, export',
        onTap: () {
          if (widget.onOpenSettings != null) {
            widget.onOpenSettings!();
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PokeBinderSpacing.sp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MORE', style: PokeBinderText.eyebrow),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('Everything Else', style: PokeBinderText.heading),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text(
                'Profile, stats, lists, and preferences',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),
              _MorePanel(rows: rows),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreRowData {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreRowData({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _MorePanel extends StatelessWidget {
  final List<_MoreRowData> rows;

  const _MorePanel({required this.rows});

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
            for (var i = 0; i < rows.length; i++) ...[
              if (i != 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: PokeBinderSpacing.sp3 + 44 + PokeBinderSpacing.sp3,
                  endIndent: PokeBinderSpacing.sp3,
                  color: PokeBinderColors.ink.withValues(alpha: 0.06),
                ),
              _MoreRow(data: rows[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  final _MoreRowData data;

  const _MoreRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PokeBinderSpacing.sp3,
            vertical: PokeBinderSpacing.sp3,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: data.gradient,
                ),
                child: Icon(data.icon, size: 18, color: PokeBinderColors.white),
              ),
              const SizedBox(width: PokeBinderSpacing.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: PokeBinderText.listRowTitle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(data.subtitle, style: PokeBinderText.listRowSubtitle),
                  ],
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: PokeBinderColors.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}