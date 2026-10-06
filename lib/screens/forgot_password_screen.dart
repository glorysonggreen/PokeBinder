import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';
import '../services/audio_service.dart';
import '../widgets/pokebinder_background.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

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
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter the email on your account to continue.');
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = "Couldn't send that — check the email and try again.";
      });
    }
  }

  void _backToLogin() => Navigator.of(context).maybePop();

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
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('Reset Your Password', style: PokeBinderText.heading),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text(
                "Enter the email on your account and we'll send you a "
                'reset link.',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),
              if (sentToEmail == null) ...[
                LabeledFormField(
                  label: 'Email',
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
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
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: PokeBinderSpacing.sp5,
                    vertical: PokeBinderSpacing.sp5,
                  ),
                  decoration: BoxDecoration(
                    color: PokeBinderColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: PokeBinderColors.ink.withValues(alpha: 0.08),
                    ),
                    boxShadow: kCardElevation,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFA8DBA0), Color(0xFF4F8F47)],
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: PokeBinderColors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: PokeBinderSpacing.sp4),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: PokeBinderText.subtitle,
                          children: [
                            const TextSpan(text: 'Check '),
                            TextSpan(
                              text: sentToEmail,
                              style: const TextStyle(
                                color: PokeBinderColors.ink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text: ' for a link to reset your password.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: PokeBinderSpacing.sp5),
                PillButton(label: 'Back to Log In', onTap: _backToLogin),
              ],
              const SizedBox(height: PokeBinderSpacing.sp4),
              Center(
                child: AuthLinkText(
                  prefix: 'Remembered it? ',
                  linkLabel: 'Log In',
                  onTap: _backToLogin,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
