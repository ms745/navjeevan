import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/constants/route_names.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      context.go(NavJeevanRoutes.roleSelect);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: NavJeevanColors.bgGradient,
        ),
        child: Column(
          children: [
            const Spacer(),
            // Central Branding
            Column(
              children: [
                // Animated Lottie Flower
                SizedBox(
                  height: 200,
                  width: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: NavJeevanColors.blush.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ).animate().scale(
                        duration: 2.seconds,
                        curve: Curves.easeInOut,
                      ).blur(begin: const Offset(0, 0), end: const Offset(30, 30)),
                      
                      const Icon(
                        Icons.local_florist_rounded,
                        size: 100,
                        color: NavJeevanColors.primaryRose,
                      ).animate().fade(duration: 1.seconds).scale(delay: 500.ms),
                      
                      // In a real app, use: Lottie.asset('assets/lottie/splash_flower.json')
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'NavJeevan',
                  style: NavJeevanTextStyles.displayLarge.copyWith(
                    color: NavJeevanColors.textDark,
                    fontSize: 40,
                  ),
                ).animate().fade(duration: 800.ms).slideY(begin: 0.2, end: 0),
                Text(
                  'नव जीवन',
                  style: NavJeevanTextStyles.headlineMedium.copyWith(
                    color: NavJeevanColors.textDark.withOpacity(0.8),
                    fontSize: 24,
                  ),
                ).animate().fade(delay: 300.ms, duration: 800.ms),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Secure Child Adoption & Mother Support Platform',
                    textAlign: TextAlign.center,
                    style: NavJeevanTextStyles.bodyLarge.copyWith(
                      color: NavJeevanColors.textSoft,
                    ),
                  ),
                ).animate().fade(delay: 600.ms, duration: 800.ms),
              ],
            ),
            const Spacer(),
            // Bottom Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0.65,
                      minHeight: 6,
                      backgroundColor: NavJeevanColors.borderColor.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(NavJeevanColors.roseLight),
                    ),
                  ).animate().shimmer(duration: 2.seconds, color: NavJeevanColors.blush),
                  const SizedBox(height: 16),
                  Text(
                    'Setting up your secure space...',
                    style: NavJeevanTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBadge(Icons.verified_user_rounded, 'SECURE'),
                      const SizedBox(width: 16),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: NavJeevanColors.textSoft, shape: BoxShape.circle)),
                      const SizedBox(width: 16),
                      _buildBadge(Icons.favorite_rounded, 'COMPASSIONATE'),
                    ],
                  ).animate().fade(delay: 1.seconds),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: NavJeevanColors.textSoft),
        const SizedBox(width: 4),
        Text(
          label,
          style: NavJeevanTextStyles.bodySmall.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
