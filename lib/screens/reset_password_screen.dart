import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';
import '../services/audio_service.dart';
import '../widgets/pokebinder_background.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const _minLength = AuthService.minPasswordLength;

  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _save() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.length < _minLength) {
      setState(
        () => _error = 'Use at least $_minLength characters for your password.',
      );
      return;
    }
    if (password != confirm) {
      setState(() => _error = "Passwords don't match — check and try again.");
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await AuthService.updatePassword(password);
      if (!mounted) return;
      PokeBinderAudio.play(Sfx.success);
      setState(() {
        _submitting = false;
        _done = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = AuthService.passwordChangeErrorMessage(e);
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
              Text('Choose a New Password', style: PokeBinderText.heading),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text(
                _done
                    ? 'Your password has been changed.'
                    : 'Pick a new password for your account.',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),
              if (!_done) ...[
                LabeledFormField(
                  label: 'New password',
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
                LabeledFormField(
                  label: 'Confirm new password',
                  child: TextField(
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitting ? null : _save(),
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
                if (_error != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: PokeBinderSpacing.sp3),
                    child: AnimatedFormError(message: _error!),
                  ),
                const SizedBox(height: PokeBinderSpacing.sp2),
                PillButton(
                  label: _submitting ? 'Saving…' : 'Save New Password',
                  enabled: !_submitting,
                  loading: _submitting,
                  onTap: _save,
                ),
              ] else
                PillButton(
                  label: 'Continue',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
