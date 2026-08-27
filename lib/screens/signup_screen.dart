import 'package:flutter/material.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';
import 'app_shell.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  void _attemptSignUp() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Fill in every field to continue.');
      return;
    }
    if (password != confirm) {
      setState(
        () => _error = "Passwords don't match — check and try again.",
      );
      return;
    }

    setState(() => _error = null);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AppShell(trainerName: name)),
      (route) => false,
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
              BackLink(onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('CREATE ACCOUNT', style: PokeBinderText.eyebrow),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text('Create your account', style: PokeBinderText.heading),
              const SizedBox(height: 4),
              Text(
                'Start tracking your collection in minutes.',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),

              LabeledFormField(
                label: 'Trainer name',
                child: TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: pokeInputDecoration(
                    hint: 'Ash K.',
                    icon: Icons.person_outline,
                  ),
                  onChanged: (_) => _clearError(),
                ),
              ),
              LabeledFormField(
                label: 'Email',
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: pokeInputDecoration(
                    hint: 'ash@pallettown.com',
                    icon: Icons.mail_outline,
                  ),
                  onChanged: (_) => _clearError(),
                ),
              ),
              FormFieldRow(
                left: LabeledFormField(
                  label: 'Password',
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: pokeInputDecoration(
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      suffixIcon: PasswordVisibilityToggle(
                        obscured: _obscurePassword,
                        onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    onChanged: (_) => _clearError(),
                  ),
                ),
                right: LabeledFormField(
                  label: 'Confirm password',
                  child: TextField(
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    decoration: pokeInputDecoration(
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      suffixIcon: PasswordVisibilityToggle(
                        obscured: _obscureConfirm,
                        onTap: () => setState(
                          () => _obscureConfirm = !_obscureConfirm,
                        ),
                      ),
                    ),
                    onChanged: (_) => _clearError(),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp2),
                  child: Text(_error!, style: PokeBinderText.formError),
                ),

              const SizedBox(height: PokeBinderSpacing.sp1),
              PillButton(
                label: '+ Create account',
                onTap: _attemptSignUp,
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),

              Center(
                child: AuthLinkText(
                  prefix: 'Already have an account? ',
                  linkLabel: 'Log in',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
