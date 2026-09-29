import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/pip_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/marlink_button.dart';
import '../../../../core/widgets/marlink_text_field.dart';
import '../../home/presentation/main_navigation_screen.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  String? _localError;

  @override
  void initState() {
    super.initState();
    PipService.instance.setAutoPip(false);
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _localError = null);

    final success = await ref.read(authNotifierProvider.notifier).login(
          _loginController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (mounted) {
      final error = ref.read(authNotifierProvider).errorMessage;
      setState(() => _localError = error ?? 'Login failed. Please check your credentials.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PipService.instance.isPipMode,
      builder: (context, isPip, _) {
        if (isPip) {
          return const Scaffold(
            backgroundColor: Color(0xFF040A18),
            body: Center(
              child: Icon(Icons.shield_rounded, color: AppColors.brandSky, size: 36),
            ),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final authState = ref.watch(authNotifierProvider);

        return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF040A18),
                    const Color(0xFF0A142E),
                    const Color(0xFF060D1E),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFFFFFFF),
                    const Color(0xFFE2E8F0),
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 1. Sleek Ambient Aura Glowing Orbs
              Positioned(
                top: -90,
                right: -70,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.20 : 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 60,
                left: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.14 : 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Main Centered Form Container
              Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // App Brand Icon with Soft Radial Aura (No double container!)
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.42),
                                    blurRadius: 32,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            Image.asset(
                              'assets/images/app_logo.png',
                              width: 74,
                              height: 74,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(
                                  Icons.share_location_rounded,
                                  color: AppColors.brandSky,
                                  size: 40,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Brand Title & Tagline
                        const Text(
                          'MarLink',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.9,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Connect  •  Locate  •  Stay Together',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Error Banner if login fails
                        if (_localError != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.alertEmergency.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.alertEmergency.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.alertEmergency,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _localError!,
                                    style: const TextStyle(
                                      color: AppColors.alertEmergency,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Elevated Form Card
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0B1733).withValues(alpha: 0.85)
                                : Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1E2F54) : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.07),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Enter your credentials to access your circle',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Username / Email input
                              MarLinkTextField(
                                controller: _loginController,
                                label: 'Email or Username',
                                hint: 'Username or email address',
                                prefixIcon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter your username or email.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password input
                              MarLinkTextField(
                                controller: _passwordController,
                                label: 'Password',
                                hint: 'Enter your password',
                                prefixIcon: Icons.lock_outline_rounded,
                                isPassword: true,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Please enter your password.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Remember Me Checkbox Row
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (val) => setState(() => _rememberMe = val ?? true),
                                      activeColor: AppColors.brandSky,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Keep me logged in',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),

                              // Primary Action Button
                              MarLinkButton(
                                text: 'Sign In',
                                icon: Icons.arrow_forward_rounded,
                                onPressed: _handleLogin,
                                isLoading: authState.isLoading,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Switch to Register Screen Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                );
                              },
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandSky,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
