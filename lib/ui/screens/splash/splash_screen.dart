import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/providers.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  /// Called once auth state is known (isLoading becomes false)
  Future<void> _tryNavigate(AuthProvider auth) async {
    if (_navigated || !mounted) return;
    // Minimum 2-second brand display
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _navigated = true;

    if (auth.isLoggedIn) {
      // Route based on role — admin/staff → /admin, user → /home
      context.go(auth.isAdmin ? '/admin' : '/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Trigger navigation once Firebase auth state settles
    if (!auth.isLoading) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _tryNavigate(auth));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo mark
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gold, width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    'SV',
                    style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('STYLE', style: AppTextStyles.displayMedium),
              Text(
                'VAULT',
                style: AppTextStyles.displayMedium
                    .copyWith(color: AppColors.gold, letterSpacing: 12),
              ),
              const SizedBox(height: 8),
              Text(
                'FASHION REDEFINED',
                style: AppTextStyles.labelGold.copyWith(letterSpacing: 4),
              ),
              const SizedBox(height: 80),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 1, color: AppColors.gold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}