import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/parent_colors.dart';

class AgencyAuthScreen extends StatefulWidget {
  const AgencyAuthScreen({super.key});

  @override
  State<AgencyAuthScreen> createState() => _AgencyAuthScreenState();
}

class _AgencyAuthScreenState extends State<AgencyAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _loginIdController = TextEditingController(
    text: 'NGO101',
  );
  final TextEditingController _loginPinController = TextEditingController(
    text: '1234',
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginIdController.dispose();
    _loginPinController.dispose();
    super.dispose();
  }

  void _enterAgencySystem() {
    context.go(NavJeevanRoutes.agencyRequestsDashboard);
  }

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final logoSize = (shortestSide * 0.18).clamp(68.0, 94.0).toDouble();

    return Scaffold(
      backgroundColor: ParentThemeColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ParentThemeColors.pureWhite,
        title: const Text(
          'Agency / NGO Access',
          style: TextStyle(
            color: ParentThemeColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ParentThemeColors.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0F2FE), Color(0xFFFCE7F3)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ParentThemeColors.primaryBlue.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Trusted operations panel for requests, responses, counselors, and welfare monitoring.',
                  style: TextStyle(
                    fontSize: 13,
                    color: ParentThemeColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ParentThemeColors.pureWhite,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: ParentThemeColors.pureWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: ParentThemeColors.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: ParentThemeColors.pureWhite,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: ParentThemeColors.primaryBlue.withValues(alpha: 0.14),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: ParentThemeColors.primaryBlue,
                  unselectedLabelColor: ParentThemeColors.textMid,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Login'),
                    Tab(text: 'Registration'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildLoginCard(), _buildRegisterCard()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ParentThemeColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ParentThemeColors.borderColor.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agency Login',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ParentThemeColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ParentThemeColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Active Tab: Login',
                style: TextStyle(
                  color: ParentThemeColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _loginIdController,
              decoration: const InputDecoration(
                labelText: 'Agency / NGO ID',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _loginPinController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Secure PIN',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enterAgencySystem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ParentThemeColors.primaryBlue,
                  foregroundColor: ParentThemeColors.pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Login to Agency Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterCard() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ParentThemeColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ParentThemeColors.borderColor.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Register Agency / NGO',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ParentThemeColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ParentThemeColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Active Tab: Registration',
                style: TextStyle(
                  color: ParentThemeColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Organization Name',
                prefixIcon: Icon(Icons.corporate_fare_outlined),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Registration Number',
                prefixIcon: Icon(Icons.verified_user_outlined),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Official Contact',
                prefixIcon: Icon(Icons.call_outlined),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enterAgencySystem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ParentThemeColors.primaryBlue,
                  foregroundColor: ParentThemeColors.pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Register & Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
