import 'package:flutter/material.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is coming soon')),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: PokeBinderColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: PokeBinderColors.redGradient,
              ),
              child: const Icon(
                Icons.catching_pokemon,
                size: 18,
                color: PokeBinderColors.white,
              ),
            ),
            const SizedBox(width: PokeBinderSpacing.sp3),
            Text('PokéBinder', style: PokeBinderText.heading),
          ],
        ),
        content: const Text(
          'Track, organize, and value your Pokémon card collection — '
          'binders, decks, wishlists, and trades in one place.\n\n'
          'Version 1.0.0',
          style: PokeBinderText.subtitle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Close',
              style: TextStyle(
                color: PokeBinderColors.redDeep,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      _SettingsRowData(
        icon: Icons.person_outline_rounded,
        title: 'Account',
        onTap: () => _comingSoon(context, 'Account'),
      ),
      _SettingsRowData(
        icon: Icons.payments_outlined,
        title: 'Currency',
        trailing: '₱ PHP',
        onTap: () => _comingSoon(context, 'Currency'),
      ),
      _SettingsRowData(
        icon: Icons.cloud_sync_outlined,
        title: 'Backup & sync',
        onTap: () => _comingSoon(context, 'Backup & sync'),
      ),
      _SettingsRowData(
        icon: Icons.notifications_none_rounded,
        title: 'Notifications',
        onTap: () => _comingSoon(context, 'Notifications'),
      ),
      _SettingsRowData(
        icon: Icons.file_download_outlined,
        title: 'Export collection',
        onTap: () => _comingSoon(context, 'Export collection'),
      ),
      _SettingsRowData(
        icon: Icons.info_outline_rounded,
        title: 'About PokéBinder',
        onTap: () => _showAbout(context),
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
              BackLink(
                label: '‹ More',
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text('SETTINGS', style: PokeBinderText.eyebrow),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('Preferences', style: PokeBinderText.heading),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text(
                'Account, backup, and export options.',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),
              _SettingsPanel(rows: rows),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRowData {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  const _SettingsRowData({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });
}

class _SettingsPanel extends StatelessWidget {
  final List<_SettingsRowData> rows;

  const _SettingsPanel({required this.rows});

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
                  indent: PokeBinderSpacing.sp3 + 32 + PokeBinderSpacing.sp3,
                  endIndent: PokeBinderSpacing.sp3,
                  color: PokeBinderColors.ink.withValues(alpha: 0.06),
                ),
              _SettingsRow(data: rows[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final _SettingsRowData data;

  const _SettingsRow({required this.data});

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
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PokeBinderColors.cream2.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(data.icon, size: 16, color: PokeBinderColors.redDeep),
              ),
              const SizedBox(width: PokeBinderSpacing.sp3),
              Expanded(
                child: Text(
                  data.title,
                  style: PokeBinderText.listRowTitle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
              if (data.trailing != null) ...[
                Text(data.trailing!, style: PokeBinderText.listRowSubtitle),
                const SizedBox(width: PokeBinderSpacing.sp2),
              ],
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
