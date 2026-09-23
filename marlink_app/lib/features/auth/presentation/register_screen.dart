import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/marlink_button.dart';
import '../../../../core/widgets/marlink_text_field.dart';
import '../../home/presentation/main_navigation_screen.dart';
import '../providers/auth_provider.dart';
import 'widgets/server_config_dialog.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _localError;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _localError = null);

    final success = await ref.read(authNotifierProvider.notifier).register(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
        );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else if (mounted) {
      final error = ref.read(authNotifierProvider).errorMessage;
      setState(() => _localError = error ?? 'Registration failed. Please check form.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF0F1A34).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
              border: Border.all(
                color: isDark ? const Color(0xFF1E2F54) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : AppColors.brandNavy,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              onTap: () => ServerConfigDialog.show(context, onConfigSaved: () => setState(() {})),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkSurface : AppColors.lightSurface).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.dns_rounded, size: 12, color: AppColors.brandSky),
                    const SizedBox(width: 5),
                    Text(
                      AppConfig.serverAddress,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.settings, size: 11, color: AppColors.brandSky),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF060D1E),
                    const Color(0xFF0B1733),
                    const Color(0xFF081024),
                  ]
                : [
                    const Color(0xFFF1F5F9),
                    const Color(0xFFFFFFFF),
                    const Color(0xFFE2E8F0),
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Ambient Glow Aura
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.16 : 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Scrollable Content
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF38BDF8)),
                                SizedBox(width: 6),
                                Text(
                                  'NEW ACCOUNT',
                                  style: TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Join MarLink to connect with loved ones, share real-time GPS coordinates, and stay protected.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_localError != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.alertEmergency.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.alertEmergency.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.alertEmergency, size: 20),
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
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => ServerConfigDialog.show(
                                    context,
                                    onConfigSaved: () => setState(() => _localError = null),
                                  ),
                                  icon: const Icon(Icons.settings_ethernet_rounded, size: 14),
                                  label: const Text(
                                    'Change Server IP',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: AppColors.brandSky,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Card Form Container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F1A34).withValues(alpha: 0.75)
                              : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E2F54) : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MarLinkTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              hint: 'e.g. Mark Lawrence',
                              prefixIcon: Icons.badge_outlined,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Full name is required.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            MarLinkTextField(
                              controller: _usernameController,
                              label: 'Username',
                              hint: 'e.g. mark_lawrence',
                              prefixIcon: Icons.alternate_email_rounded,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Username is required.';
                                if (val.trim().length < 3) return 'Username must be at least 3 characters.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            MarLinkTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              hint: 'e.g. mark@example.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Email is required.';
                                if (!val.contains('@') || !val.contains('.')) return 'Enter a valid email address.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            MarLinkTextField(
                              controller: _phoneController,
                              label: 'Phone Number (Optional)',
                              hint: 'e.g. +639171234567',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),

                            MarLinkTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'Min. 8 characters',
                              prefixIcon: Icons.lock_outline_rounded,
                              isPassword: true,
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Password is required.';
                                if (val.length < 8) return 'Password must be at least 8 characters.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            MarLinkTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              hint: 'Re-enter your password',
                              prefixIcon: Icons.lock_clock_outlined,
                              isPassword: true,
                              validator: (val) {
                                if (val != _passwordController.text) return 'Passwords do not match.';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      MarLinkButton(
                        text: 'Create My Account',
                        icon: Icons.person_add_alt_1_rounded,
                        onPressed: _handleRegister,
                        isLoading: authState.isLoading,
                      ),
                      const SizedBox(height: 16),

                      // Trust Note
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_outlined, size: 14, color: AppColors.statusOnline),
                            const SizedBox(width: 6),
                            Text(
                              'Your location data is private & encrypted',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Footer
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandSky,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
