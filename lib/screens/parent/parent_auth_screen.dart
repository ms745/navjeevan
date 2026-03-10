import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/parent_colors.dart';
import '../../core/widgets/error_popup.dart';
import '../../providers/auth_provider.dart';

class ParentAuthScreen extends StatefulWidget {
  const ParentAuthScreen({super.key});

  @override
  State<ParentAuthScreen> createState() => _ParentAuthScreenState();
}

class _ParentAuthScreenState extends State<ParentAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAuthActionInProgress = false;

  final TextEditingController _loginPhoneController = TextEditingController(
    text: '9876509999',
  );
  final TextEditingController _loginPinController = TextEditingController(
    text: '1234',
  );
  final TextEditingController _registerPhoneController = TextEditingController(
    text: '9876509999',
  );
  final TextEditingController _registerPinController = TextEditingController(
    text: '1234',
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginPhoneController.dispose();
    _loginPinController.dispose();
    _registerPhoneController.dispose();
    _registerPinController.dispose();
    super.dispose();
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    if (_isAuthActionInProgress) {
      return;
    }
    setState(() => _isAuthActionInProgress = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isAuthActionInProgress = false);
      }
    }
  }

  Future<void> _continueToParentFlow() async {
    final phone = _loginPhoneController.text.trim();
    final password = _loginPinController.text.trim();
    if (phone.isEmpty || password.isEmpty) {
      showErrorBottomPopup(context, 'Enter phone and password.');
      return;
    }

    try {
      await context.read<AuthProvider>().loginWithPhonePin(
        phone: phone,
        pin: password,
        expectedRole: 'parent',
      );
      if (!mounted) {
        return;
      }
      context.push(NavJeevanRoutes.parentVerificationStatus);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorBottomPopup(context, 'Parent login failed: $error');
    }
  }

  Future<void> _startRegistration() async {
    final phone = _registerPhoneController.text.trim();
    final password = _registerPinController.text.trim();
    if (phone.isEmpty || password.isEmpty) {
      showErrorBottomPopup(context, 'Enter phone and password to register.');
      return;
    }

    try {
      await context.read<AuthProvider>().registerWithPhonePin(
        phone: phone,
        pin: password,
        role: 'parent',
      );
      if (!mounted) {
        return;
      }
      context.push(NavJeevanRoutes.parentRegistrationWizard);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorBottomPopup(context, 'Parent registration failed: $error');
    }
  }

  Future<void> _continueParentWithGoogle() async {
    try {
      await context.read<AuthProvider>().signInWithGoogle(
        expectedRole: 'parent',
        profile: {'entry': 'google'},
      );
      if (!mounted) {
        return;
      }
      context.push(NavJeevanRoutes.parentVerificationStatus);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorBottomPopup(context, 'Parent Google login failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ParentThemeColors.pureWhite,
        elevation: 0,
        title: const Text(
          'Adoptive Parent Access',
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
      body: Container(
        decoration: const BoxDecoration(gradient: ParentThemeColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                _buildTopBanner(),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: ParentThemeColors.iceBlue,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ParentThemeColors.borderColor),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      gradient: ParentThemeColors.trustGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ParentThemeColors.primaryBlue.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    dividerColor: Colors.transparent,
                    labelPadding: const EdgeInsets.symmetric(vertical: 10),
                    labelColor: ParentThemeColors.pureWhite,
                    unselectedLabelColor: ParentThemeColors.textSoft,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    tabs: const [
                      Tab(text: 'Login', height: 54),
                      Tab(text: 'Register', height: 54),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: ParentThemeColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ParentThemeColors.borderColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.primaryBlue.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: ParentThemeColors.trustGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ParentThemeColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: ParentThemeColors.pureWhite,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Secure & Trusted Platform',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ParentThemeColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your data is encrypted • Protected by law',
                  style: TextStyle(
                    fontSize: 13,
                    color: ParentThemeColors.textMid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ParentThemeColors.borderColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    final isLoading =
        context.watch<AuthProvider>().isLoading || _isAuthActionInProgress;
    return _buildAuthCard(
      children: [
        const Text(
          'Secure Login',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ParentThemeColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Use your registered mobile number and PIN to continue your adoption journey.',
          style: TextStyle(fontSize: 14, color: ParentThemeColors.textMid),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _loginPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter 10-digit number',
            prefixIcon: Icon(
              Icons.phone_outlined,
              color: ParentThemeColors.primaryBlue,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ParentThemeColors.borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ParentThemeColors.primaryBlue,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _loginPinController,
          keyboardType: TextInputType.visiblePassword,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter secure password',
            prefixIcon: Icon(
              Icons.lock_outline,
              color: ParentThemeColors.primaryBlue,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ParentThemeColors.borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ParentThemeColors.primaryBlue,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ParentThemeColors.skyBlue.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ParentThemeColors.primaryBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: ParentThemeColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Demo: 9876509999 • 1234',
                  style: TextStyle(
                    fontSize: 13,
                    color: ParentThemeColors.textMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () => _runAuthAction(_continueToParentFlow),
            style: ElevatedButton.styleFrom(
              backgroundColor: ParentThemeColors.primaryBlue,
              foregroundColor: ParentThemeColors.pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ParentThemeColors.pureWhite,
                      ),
                    ),
                  )
                : const Text(
                    'Login & Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoading
                ? null
                : () => _runAuthAction(_continueParentWithGoogle),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.g_mobiledata_rounded, size: 24),
            label: Text(isLoading ? 'Please wait...' : 'Continue with Google'),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterCard() {
    final isLoading =
        context.watch<AuthProvider>().isLoading || _isAuthActionInProgress;
    return _buildAuthCard(
      children: [
        const Text(
          'Start Your Journey',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ParentThemeColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Begin your adoption journey with us. We\'ll guide you every step of the way.',
          style: TextStyle(fontSize: 14, color: ParentThemeColors.textMid),
        ),
        const SizedBox(height: 24),
        _buildInfoCard(
          icon: Icons.verified_user,
          title: 'Verified Process',
          description: 'Government-approved adoption framework',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.support_agent,
          title: 'Expert Support',
          description: '24/7 guidance from counselors and legal experts',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.favorite,
          title: 'Post-Adoption Care',
          description: 'Continuous support for your family journey',
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _registerPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter 10-digit number',
            prefixIcon: Icon(
              Icons.phone_outlined,
              color: ParentThemeColors.primaryBlue,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ParentThemeColors.borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ParentThemeColors.primaryBlue,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _registerPinController,
          keyboardType: TextInputType.visiblePassword,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Set Password',
            hintText: 'Create secure password',
            prefixIcon: Icon(
              Icons.lock_outline,
              color: ParentThemeColors.primaryBlue,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ParentThemeColors.borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ParentThemeColors.primaryBlue,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () => _runAuthAction(_startRegistration),
            style: ElevatedButton.styleFrom(
              backgroundColor: ParentThemeColors.primaryBlue,
              foregroundColor: ParentThemeColors.pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ParentThemeColors.pureWhite,
                      ),
                    ),
                  )
                : const Text(
                    'Start Registration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: ParentThemeColors.lightTrustGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ParentThemeColors.borderColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ParentThemeColors.primaryBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ParentThemeColors.pureWhite, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ParentThemeColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: ParentThemeColors.textMid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
