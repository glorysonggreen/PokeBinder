import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/pokeball.dart';
import '../widgets/pokebinder_form_fields.dart';
import 'app_shell.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  String? _error;
  int _errorTick = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _attemptLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Enter an email and password to continue.';
        _errorTick++;
      });
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await AuthService.signIn(email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not log in — check your email and password.';
        _errorTick++;
      });
    }
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  void _openSignUp() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SignUpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            PokeBinderSpacing.sp4,
            PokeBinderSpacing.sp6,
            PokeBinderSpacing.sp4,
            PokeBinderSpacing.sp6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AuthBanner(
                heading: 'Welcome to PokéBinder',
                subtitle: 'Log in to sync your collection',
              ),
              const SizedBox(height: PokeBinderSpacing.sp6),

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
              LabeledFormField(
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
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
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

              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp4),
                  child: AuthLinkText(
                    linkLabel: 'Forgot Password',
                    onTap: _openForgotPassword,
                  ),
                ),
              ),

              PillButton(
                label: _submitting ? 'Logging In…' : 'Log In',
                enabled: !_submitting,
                loading: _submitting,
                onTap: _attemptLogin,
              ),
              const SizedBox(height: PokeBinderSpacing.sp6),

              Center(
                child: AuthLinkText(
                  prefix: "Don't have an account? ",
                  linkLabel: 'Sign Up',
                  onTap: _openSignUp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthBanner extends StatelessWidget {
  final String heading;
  final String subtitle;

  const _AuthBanner({
    required this.heading,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: PokeBinderSpacing.sp5,
        vertical: PokeBinderSpacing.sp6,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PokeBinderColors.white, Color(0xFFF7EFE0)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: kCardElevation,
      ),
      child: Column(
        children: [
          const PopIn(child: PokeballBadge(size: 64)),
          const SizedBox(height: PokeBinderSpacing.sp4),
          FadeSlideIn(
            index: 1,
            child: Text(
              heading,
              textAlign: TextAlign.center,
              style: PokeBinderText.heading,
            ),
          ),
          const SizedBox(height: PokeBinderSpacing.sp1),
          FadeSlideIn(
            index: 2,
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: PokeBinderText.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}
