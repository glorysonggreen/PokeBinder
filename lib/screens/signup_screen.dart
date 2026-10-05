import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/trainer_profile_repository.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';
import 'app_shell.dart';
import '../services/audio_service.dart';
import '../widgets/pokebinder_background.dart';

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
  bool _submitting = false;
  String? _error;
  int _errorTick = 0;

  @override
  void initState() {
    super.initState();
    PokeBinderAudio.music(MusicTrack.title);
  }

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

  Future<void> _attemptSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Fill in every field to continue.';
        _errorTick++;
      });
      return;
    }
    if (password != confirm) {
      setState(() {
        _error = "Passwords don't match — check and try again.";
        _errorTick++;
      });
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await AuthService.signUp(
        email: email,
        password: password,
        trainerName: name,
      );
      if (!AuthService.isSignedIn) {
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _error = 'Check your email to confirm your account, then log in.';
          _errorTick++;
        });
        return;
      }
      await TrainerProfileRepository.load(fallbackName: name);
      if (!mounted) return;
      PokeBinderAudio.play(Sfx.success);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AppShell(trainerName: name)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not create that account — try again.';
        _errorTick++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PokeBinderScaffold(
      backdrop: PokeBinderBackdrop.pokeball,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: PokeBinderSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackLink(onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('Create Your Account', style: PokeBinderText.heading),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text(
                'Start tracking your collection in minutes.',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),

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
                  padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp3),
                  child: AnimatedFormError(
                    message: _error!,
                    pulse: _errorTick,
                  ),
                ),

              const SizedBox(height: PokeBinderSpacing.sp2),
              PillButton(
                label: _submitting ? 'Creating Account…' : '+ Create Account',
                enabled: !_submitting,
                loading: _submitting,
                onTap: _attemptSignUp,
              ),
              const SizedBox(height: PokeBinderSpacing.sp5),

              Center(
                child: AuthLinkText(
                  prefix: 'Already have an account? ',
                  linkLabel: 'Log In',
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
