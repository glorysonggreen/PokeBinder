import 'package:flutter/material.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  String? _error;
  String? _sentToEmail;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter the email on your account to continue.');
      return;
    }

    setState(() {
      _error = null;
      _sentToEmail = email;
    });
  }

  void _backToLogin() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final sentToEmail = _sentToEmail;

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
              BackLink(onTap: _backToLogin),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('ACCOUNT RECOVERY', style: PokeBinderText.eyebrow),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text('Reset your password', style: PokeBinderText.heading),
              const SizedBox(height: 4),
              Text(
                "Enter the email on your account and we'll send you a "
                'reset link.',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),

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
                    padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp2),
                    child: Text(_error!, style: PokeBinderText.formError),
                  ),
                PillButton(label: 'Send reset link', onTap: _sendResetLink),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: PokeBinderSpacing.sp4,
                    vertical: PokeBinderSpacing.sp4,
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
                      const SizedBox(height: PokeBinderSpacing.sp3),
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
                const SizedBox(height: PokeBinderSpacing.sp4),
                PillButton(label: 'Back to log in', onTap: _backToLogin),
              ],

              const SizedBox(height: PokeBinderSpacing.sp3),
              Center(
                child: AuthLinkText(
                  prefix: 'Remembered it? ',
                  linkLabel: 'Log in',
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
