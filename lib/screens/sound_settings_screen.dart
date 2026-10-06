import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_background.dart';

class SoundSettingsScreen extends StatelessWidget {
  const SoundSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = PokeBinderAudio.instance;

    return PokeBinderScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: PokeBinderSpacing.page,
          child: AnimatedBuilder(
            animation: audio,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackLink(onTap: () => Navigator.of(context).maybePop()),
                  const SizedBox(height: PokeBinderSpacing.sp2),
                  Text('Sound & Music', style: PokeBinderText.heading),
                  const SizedBox(height: PokeBinderSpacing.sp1),
                  Text(
                    'Background music and the little sounds that go with '
                    'your cards, binders, and buttons.',
                    style: PokeBinderText.subtitle,
                  ),
                  const SizedBox(height: PokeBinderSpacing.sp4),
                  FadeSlideIn(
                    child: _SettingsPanel(
                      children: [
                        _SwitchRow(
                          icon: Icons.music_note_rounded,
                          gradient: PokeBinderColors.redGradient,
                          title: 'Background music',
                          subtitle: 'A looping theme while you browse',
                          value: audio.musicEnabled,
                          onChanged: audio.setMusicEnabled,
                        ),
                        _VolumeRow(
                          label: 'Music volume',
                          value: audio.musicVolume,
                          enabled: audio.musicEnabled,
                          onChanged: audio.setMusicVolume,
                        ),
                        const _PanelDivider(),
                        _SwitchRow(
                          icon: Icons.graphic_eq_rounded,
                          gradient: PokeBinderColors.goldGradient,
                          title: 'Sound effects',
                          subtitle: 'Taps, card actions, searching, alerts',
                          value: audio.sfxEnabled,
                          onChanged: audio.setSfxEnabled,
                        ),
                        _VolumeRow(
                          label: 'Effects volume',
                          value: audio.sfxVolume,
                          enabled: audio.sfxEnabled,
                          onChanged: audio.setSfxVolume,
                          onChangeEnd: (_) => PokeBinderAudio.play(Sfx.scanFound),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: PokeBinderSpacing.sp4),
                  PillButton(
                    label: 'Play a Test Sound',
                    ghost: true,
                    icon: Icons.play_arrow_rounded,
                    enabled: audio.sfxEnabled,
                    onTap: () => PokeBinderAudio.play(Sfx.success),
                  ),
                  const SizedBox(height: PokeBinderSpacing.sp3),
                  Text(
                    'Your choices are remembered on this device.',
                    style: PokeBinderText.listRowSubtitle,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  final List<Widget> children;

  const _SettingsPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        boxShadow: kCardElevation,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(children: children),
      ),
    );
  }
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: PokeBinderColors.ink.withValues(alpha: 0.06),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PokeBinderSpacing.sp3,
        PokeBinderSpacing.sp3,
        PokeBinderSpacing.sp3,
        PokeBinderSpacing.sp1,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: gradient,
            ),
            child: Icon(icon, size: 18, color: PokeBinderColors.white),
          ),
          const SizedBox(width: PokeBinderSpacing.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: PokeBinderText.rowTitle),
                const SizedBox(height: PokeBinderSpacing.sp0),
                Text(subtitle, style: PokeBinderText.listRowSubtitle),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _VolumeRow extends StatelessWidget {
  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const _VolumeRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final percent = '${(value * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PokeBinderSpacing.sp3,
        0,
        PokeBinderSpacing.sp3,
        PokeBinderSpacing.sp3,
      ),
      child: Row(
        children: [
          Icon(
            value <= 0 ? Icons.volume_mute_rounded : Icons.volume_down_rounded,
            size: 18,
            color: PokeBinderColors.inkSoft,
          ),
          Expanded(
            child: Slider(
              value: value,
              onChanged: enabled ? onChanged : null,
              onChangeEnd: enabled ? onChangeEnd : null,
              activeColor: PokeBinderColors.red,
              inactiveColor: PokeBinderColors.cream2,
              label: percent,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              percent,
              textAlign: TextAlign.right,
              semanticsLabel: '$label $percent',
              style: PokeBinderText.listRowSubtitle,
            ),
          ),
        ],
      ),
    );
  }
}
