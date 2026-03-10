import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/constants/route_names.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NavJeevan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Text(
                'Select Your Role',
                style: NavJeevanTextStyles.headlineMedium.copyWith(
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Choose how you'd like to use the platform today",
                textAlign: TextAlign.center,
                style: NavJeevanTextStyles.bodyLarge.copyWith(
                  color: NavJeevanColors.textSoft,
                ),
              ),
              const SizedBox(height: 32),

              _buildRoleCard(
                context,
                title: 'Mother Seeking Help',
                subtitle:
                    'Confidential assistance, counseling, and NGO discovery',
                icon: Icons.favorite_rounded,
                color: NavJeevanColors.blush,
                onTap: () => context.push(NavJeevanRoutes.motherAuth),
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                context,
                title: 'Adoptive Parent',
                subtitle: 'Legal adoption registration and document tracking',
                icon: Icons.family_restroom_rounded,
                color: NavJeevanColors.petalLight,
                onTap: () {
                  // Navigate to parent flow
                },
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                context,
                title: 'Adoption Agency / NGO',
                subtitle: 'Manage mother requests and coordinate support',
                icon: Icons.groups_rounded,
                color: NavJeevanColors.blush,
                onTap: () {
                  // Navigate to agency flow
                },
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                context,
                title: 'Government Admin',
                subtitle:
                    'Analytics, welfare monitoring, and AI risk prediction',
                icon: Icons.admin_panel_settings_rounded,
                color: NavJeevanColors.petalLight,
                onTap: () {
                  // Navigate to admin flow
                },
              ),

              const SizedBox(height: 48),
              _buildTrustBadges(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: NavJeevanColors.borderColor.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: NavJeevanColors.primaryRose.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: NavJeevanTextStyles.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: NavJeevanTextStyles.bodySmall.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NavJeevanColors.pureWhite,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: NavJeevanColors.primaryRose, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadges() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: NavJeevanColors.borderColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _badgeItem(Icons.shield_outlined, 'ANONYMOUS'),
          _badgeItem(Icons.verified_outlined, 'CARA ALIGNED'),
          _badgeItem(Icons.lock_outline, 'SECURE'),
        ],
      ),
    );
  }

  Widget _badgeItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: NavJeevanColors.textSoft, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: NavJeevanTextStyles.bodySmall.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
