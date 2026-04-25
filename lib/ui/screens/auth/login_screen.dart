import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/providers.dart';
import '../../widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  Timer? _lockoutTimer;
  int _countdownSecs = 0;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _lockoutTimer?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _startLockoutCountdown(int seconds) {
    setState(() => _countdownSecs = seconds);
    _lockoutTimer?.cancel();
    _lockoutTimer =
        Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdownSecs <= 1) {
        t.cancel();
        setState(() => _countdownSecs = 0);
        context.read<AuthProvider>().clearError();
      } else {
        setState(() => _countdownSecs--);
      }
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    final ok =
        await auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim());

    if (!mounted) return;

    if (ok) {
      // Router handles redirect based on role
      final isAdmin = auth.user?.isAdmin ?? false;
      context.go(isAdmin ? '/admin' : '/home');
    } else {
      _shakeCtrl.forward(from: 0);
      if (auth.isLockedOut && auth.lockoutSeconds > 0) {
        _startLockoutCountdown(auth.lockoutSeconds);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email address first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.sendPasswordReset(email);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Password reset email sent to $email'
            : auth.error ?? 'Failed to send reset email'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLocked = _countdownSecs > 0;
    final mins = (_countdownSecs / 60).floor();
    final secs = _countdownSecs % 60;
    final countdownText = mins > 0
        ? '$mins:${secs.toString().padLeft(2, '0')}'
        : '$secs s';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // ── Branding ──────────────────────────────────
                const Text('STYLE', style: AppTextStyles.displayLarge),
                Text('VAULT',
                    style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.gold, letterSpacing: 8)),
                const SizedBox(height: 8),
                const Text('Sign in to your account',
                    style: AppTextStyles.bodyMedium),
                const SizedBox(height: 48),

                // ── Lockout Banner ────────────────────────────
                if (isLocked)
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (_, child) => child!,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Account temporarily locked',
                                    style: TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                const SizedBox(height: 2),
                                Text('Try again in $countdownText',
                                    style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Attempts warning ──────────────────────────
                if (!isLocked &&
                    auth.attemptsRemaining < 5 &&
                    auth.attemptsRemaining > 0 &&
                    auth.error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    color: AppColors.warning.withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_outlined,
                            color: AppColors.warning, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '${auth.attemptsRemaining} attempt${auth.attemptsRemaining == 1 ? '' : 's'} remaining before lockout',
                          style: const TextStyle(
                              color: AppColors.warning, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                // ── Fields ────────────────────────────────────
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(
                        _shakeCtrl.isAnimating
                            ? 6 *
                                (_shakeAnim.value < 0.5
                                    ? _shakeAnim.value
                                    : 1 - _shakeAnim.value)
                            : 0,
                        0),
                    child: child,
                  ),
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'Email',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLocked,
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Password',
                        controller: _passCtrl,
                        obscure: true,
                        enabled: !isLocked,
                        validator: (v) => v == null || v.length < 6
                            ? 'Min 6 characters'
                            : null,
                      ),
                    ],
                  ),
                ),

                // ── Forgot password ───────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLocked ? null : _forgotPassword,
                    child: Text(
                      'Forgot password?',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: isLocked
                              ? AppColors.textMuted
                              : AppColors.gold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Error message ─────────────────────────────
                if (auth.error != null && !isLocked)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    color: AppColors.error.withValues(alpha: 0.1),
                    child: Text(
                      auth.error!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13),
                    ),
                  ),

                CustomButton(
                  label: isLocked ? 'LOCKED — $countdownText' : 'Sign In',
                  onPressed: isLocked ? null : _login,
                  isLoading: auth.isLoading,
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ",
                        style: AppTextStyles.bodyMedium),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text('Register',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.gold,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.gold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}