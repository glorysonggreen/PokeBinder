import 'dart:async';

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/auth_banner.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';
import '../services/audio_service.dart';
import '../widgets/pokebinder_background.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _resendCooldownSeconds = 60;
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  late final _emailController =
      TextEditingController(text: widget.initialEmail);

  Timer? _cooldownTimer;
  int _cooldown = 0;
  bool _submitting = false;
  String? _error;
  String? _sentToEmail;

  @override
  void initState() {
    super.initState();
    PokeBinderAudio.music(MusicTrack.title);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = _resendCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  Future<void> _sendResetLink() async {
    if (_submitting) return;
    final email = (_sentToEmail ?? _emailController.text).trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter the email on your account to continue.');
      return;
    }
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = "That email address doesn't look right.");
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await AuthService.sendPasswordResetEmail(email);
      if (!mounted) return;
      PokeBinderAudio.play(Sfx.success);
      setState(() {
        _submitting = false;
        _sentToEmail = email;
      });
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = AuthService.resetEmailErrorMessage(e);
      });
    }
  }

  void _useDifferentEmail() {
    _cooldownTimer?.cancel();
    setState(() {
      _sentToEmail = null;
      _cooldown = 0;
      _error = null;
    });
  }

  void _backToLogin() => Navigator.of(context).maybePop();

  Widget _resendRow() {
    if (_submitting) {
      return Text(
        'Sending…',
        textAlign: TextAlign.center,
        style: PokeBinderText.subtitle,
      );
    }
    if (_cooldown > 0) {
      return Text(
        "Didn't get it? You can resend in ${_cooldown}s",
        textAlign: TextAlign.center,
        style: PokeBinderText.subtitle,
      );
    }
    return AuthLinkText(
      prefix: "Didn't get it? ",
      linkLabel: 'Resend Link',
      onTap: _sendResetLink,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sentToEmail = _sentToEmail;

    return PokeBinderScaffold(
      backdrop: PokeBinderBackdrop.pokeball,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: PokeBinderSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackLink(onTap: _backToLogin),
              const SizedBox(height: PokeBinderSpacing.sp3),
              AuthBanner(
                heading: sentToEmail == null
                    ? 'Reset Your Password'
                    : 'Check Your Email',
                subtitle: sentToEmail == null
                    ? "Enter the email on your account and we'll send "
                        'you a reset link.'
                    : 'We sent a password reset link to',
                footer: sentToEmail == null
                    ? null
                    : _EmailChip(email: sentToEmail),
              ),
              const SizedBox(height: PokeBinderSpacing.sp5),
              if (sentToEmail == null) ...[
                LabeledFormField(
                  label: 'Email',
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendResetLink(),
                    decoration: pokeInputDecoration(
                      hint: 'ash@pallettown.com',
                      icon: Icons.mail_outline,
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp3),
                    child: AnimatedFormError(message: _error!),
                  ),
                const SizedBox(height: PokeBinderSpacing.sp1),
                PillButton(
                  label: _submitting ? 'Sending…' : 'Send Reset Link',
                  enabled: !_submitting,
                  loading: _submitting,
                  onTap: _sendResetLink,
                ),
                const SizedBox(height: PokeBinderSpacing.sp6),
                Center(
                  child: AuthLinkText(
                    prefix: 'Remembered it? ',
                    linkLabel: 'Log In',
                    onTap: _backToLogin,
                  ),
                ),
              ] else ...[
                const FadeSlideIn(index: 4, child: _NextStepsCard()),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: PokeBinderSpacing.sp3),
                    child: AnimatedFormError(message: _error!),
                  ),
                const SizedBox(height: PokeBinderSpacing.sp5),
                FadeSlideIn(
                  index: 5,
                  child: PillButton(
                    label: 'Back to Log In',
                    onTap: _backToLogin,
                  ),
                ),
                const SizedBox(height: PokeBinderSpacing.sp5),
                FadeSlideIn(index: 6, child: Center(child: _resendRow())),
                const SizedBox(height: PokeBinderSpacing.sp2),
                FadeSlideIn(
                  index: 7,
                  child: Center(
                    child: AuthLinkText(
                      prefix: 'Wrong address? ',
                      linkLabel: 'Use a different email',
                      onTap: _useDifferentEmail,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailChip extends StatelessWidget {
  final String email;

  const _EmailChip({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PokeBinderSpacing.sp3,
        vertical: PokeBinderSpacing.sp2,
      ),
      decoration: BoxDecoration(
        color: PokeBinderColors.red.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: PokeBinderColors.redDeep.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.mail_outline,
            size: 16,
            color: PokeBinderColors.redDeep,
          ),
          const SizedBox(width: PokeBinderSpacing.sp2),
          Flexible(
            child: Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PokeBinderText.rowTitle.copyWith(
                fontSize: 14,
                color: PokeBinderColors.redDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStepsCard extends StatelessWidget {
  const _NextStepsCard();

  static const _steps = [
    'Open the email we just sent you.',
    'Tap the reset link. Use this same browser.',
    'Choose a new password and log back in.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PokeBinderSpacing.sp4),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        boxShadow: kCardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WHAT HAPPENS NEXT', style: PokeBinderText.sectionLabel),
          const SizedBox(height: PokeBinderSpacing.sp3),
          for (final (i, step) in _steps.indexed) ...[
            if (i > 0) const SizedBox(height: PokeBinderSpacing.sp3),
            _StepRow(number: i + 1, text: step),
          ],
          const SizedBox(height: PokeBinderSpacing.sp4),
          Divider(
            height: 1,
            thickness: 1,
            color: PokeBinderColors.ink.withValues(alpha: 0.06),
          ),
          const SizedBox(height: PokeBinderSpacing.sp3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: PokeBinderColors.inkSoft,
              ),
              const SizedBox(width: PokeBinderSpacing.sp2),
              Expanded(
                child: Text(
                  'Nothing in your inbox? Check your spam folder.',
                  style: PokeBinderText.listRowSubtitle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: PokeBinderColors.redGradient,
          ),
          child: Text(
            '$number',
            style: PokeBinderText.chipLabelActive.copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(width: PokeBinderSpacing.sp3),
        Expanded(child: Text(text, style: PokeBinderText.listRowTitle)),
      ],
    );
  }
}
