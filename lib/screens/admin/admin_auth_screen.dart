import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/constants/route_names.dart';

class AdminAuthScreen extends StatefulWidget {
  const AdminAuthScreen({super.key});

  @override
  State<AdminAuthScreen> createState() => _AdminAuthScreenState();
}

class _AdminAuthScreenState extends State<AdminAuthScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final logoSize = (shortestSide * 0.15).clamp(56.0, 80.0).toDouble();
    final logoBadgePadding = (logoSize * 0.3).clamp(14.0, 24.0).toDouble();

    return Scaffold(
      backgroundColor: NavJeevanColors.pureWhite,
      appBar: AppBar(
        title: const Text('Admin Portal'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                padding: EdgeInsets.all(logoBadgePadding),
                decoration: BoxDecoration(
                  color: NavJeevanColors.primaryRose.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Secure Admin Login',
              textAlign: TextAlign.center,
              style: NavJeevanTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: NavJeevanColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your credentials to access the analytics and monitoring dashboard',
              textAlign: TextAlign.center,
              style: NavJeevanTextStyles.bodyMedium.copyWith(
                color: NavJeevanColors.textSoft,
              ),
            ),
            const SizedBox(height: 48),
            _buildTextField(
              controller: _idController,
              label: 'Admin ID',
              icon: Icons.badge_outlined,
              hint: 'e.g., AD-2024-001',
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              hint: '••••••••',
              isPassword: true,
              obscureText: _obscurePassword,
              onToggleVisibility: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => context.go(NavJeevanRoutes.adminDashboard),
              style: ElevatedButton.styleFrom(
                backgroundColor: NavJeevanColors.primaryRose,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: NavJeevanColors.primaryRose.withValues(alpha: 0.4),
              ),
              child: const Text(
                'AUTHENTICATE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  size: 16,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  '256-bit encrypted secure session',
                  style: NavJeevanTextStyles.bodySmall.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: NavJeevanTextStyles.titleMedium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: NavJeevanColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: NavJeevanColors.textSoft.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(icon, color: NavJeevanColors.primaryRose),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: NavJeevanColors.textSoft,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: NavJeevanColors.primaryRose.withValues(alpha: 0.03),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: NavJeevanColors.borderColor.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: NavJeevanColors.primaryRose,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
