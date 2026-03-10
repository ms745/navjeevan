import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/colors.dart';
import '../core/theme/text_styles.dart';
import '../core/constants/route_names.dart';

class UpdatedLegalGuidanceScreen extends StatelessWidget {
  const UpdatedLegalGuidanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal Help for Mother'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(NavJeevanRoutes.motherProfile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [NavJeevanColors.blush, NavJeevanColors.petalLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: NavJeevanColors.primaryRose.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OFFICIAL GUIDE',
                      style: NavJeevanTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Safe & Legal Child Surrender Support',
                      style: NavJeevanTextStyles.headlineMedium.copyWith(
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Clear legal guidance for mothers who need to surrender a child through lawful and protected process.',
                      style: NavJeevanTextStyles.bodyLarge.copyWith(
                        color: NavJeevanColors.textMid,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Trust Badges
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildMiniBadge(
                    Icons.verified_rounded,
                    'CARA Aligned',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildMiniBadge(
                    Icons.support_agent_rounded,
                    'Mother First Support',
                    Colors.green,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Stepper
            _buildStep(
              1,
              'Immediate Safe Contact',
              'Reach out to CHILDLINE 1098 or nearest authorized agency. Your immediate safety and privacy are prioritized first.',
              NavJeevanColors.primaryRose,
            ),
            _buildStep(
              2,
              'Confidential Counseling & Consent',
              'A counselor explains legal options and your rights. No forced decision is valid without informed and voluntary consent.',
              NavJeevanColors.roseLight,
            ),
            _buildStep(
              3,
              'Child Welfare Committee (CWC) Process',
              'Your case is presented before the CWC through authorized channels. This ensures lawful handling of surrender and child protection.',
              NavJeevanColors.primaryRose,
            ),
            _buildStep(
              4,
              'Legal Documentation & Verification',
              'Required declarations and identity documents are recorded as per law. You receive reference details for tracking and legal continuity.',
              NavJeevanColors.roseLight,
            ),
            _buildStep(
              5,
              'Post-Surrender Mother Support',
              'You can continue receiving counseling, medical support, and legal follow-up after surrender through partner NGOs and support desks.',
              NavJeevanColors.primaryRose,
              isLast: true,
            ),

            // CTAs
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final Uri uri = Uri(scheme: 'tel', path: '1098');
                      await launchUrl(uri);
                    },
                    icon: const Icon(Icons.call_rounded),
                    label: const Text('Call Emergency Childline 1098'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NavJeevanColors.blush,
                      foregroundColor: NavJeevanColors.primaryRose,
                      side: const BorderSide(
                        color: NavJeevanColors.primaryRose,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final Uri uri = Uri.parse('https://cara.wcd.gov.in/');
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    icon: const Icon(Icons.gavel_rounded),
                    label: const Text('Open Legal Resources (CARA)'),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '"You are not alone. Legal and emotional support is available at every step."',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: NavJeevanColors.textSoft,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildMiniBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NavJeevanColors.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    int stepNum,
    String title,
    String description,
    Color color, {
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$stepNum',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!isLast)
                Container(width: 2, height: 80, color: color.withValues(alpha: 0.2)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: NavJeevanTextStyles.titleLarge.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: NavJeevanTextStyles.bodyLarge.copyWith(
                    fontSize: 14,
                    color: NavJeevanColors.textMid,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: NavJeevanColors.borderColor.withValues(alpha: 0.5)),
        ),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: NavJeevanColors.textSoft,
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(NavJeevanRoutes.motherHelpRequest);
              break;
            case 1:
              context.go(NavJeevanRoutes.motherNgoMap);
              break;
            case 2:
              context.go(NavJeevanRoutes.motherCounseling);
              break;
            case 3:
              context.go(NavJeevanRoutes.legalGuidance);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'NGO Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded),
            label: 'Counseling',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel_rounded),
            label: 'Legal',
          ),
        ],
      ),
    );
  }
}
