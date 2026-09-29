import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import 'login_screen.dart';
import '../../home/presentation/main_navigation_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else if (next.status == AuthStatus.unauthenticated || next.status == AuthStatus.error) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF040A18),
      body: Stack(
        children: [
          // 1. Ambient Background Glow Orbs
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: MediaQuery.of(context).size.width * 0.5 - 130,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0EA5E9).withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Centered Hero Branding
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edge-to-edge Squircle Logo with Soft Ambient Aura
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft glow halo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0EA5E9).withValues(alpha: 0.45),
                                blurRadius: 36,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        // Native squircle image tile (no double container!)
                        Image.asset(
                          'assets/images/app_logo.png',
                          width: 92,
                          height: 92,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              color: AppColors.brandBlue,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(
                              Icons.share_location_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Brand Typography
                    const Text(
                      'MarLink',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Connect  •  Locate  •  Stay Together',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Subtle Bottom Status / Footer
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF38BDF8).withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Text(
                        'Securing live network...',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'v1.0.0 • Protected by MarLink Shield',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
