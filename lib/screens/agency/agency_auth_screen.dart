import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/parent_colors.dart';
import '../../core/widgets/error_popup.dart';
import '../../providers/auth_provider.dart';

enum _AgencyAuthAction { none, login, google, register }

class AgencyAuthScreen extends StatefulWidget {
  const AgencyAuthScreen({super.key});

  @override
  State<AgencyAuthScreen> createState() => _AgencyAuthScreenState();
}

class _AgencyAuthScreenState extends State<AgencyAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  _AgencyAuthAction _activeAuthAction = _AgencyAuthAction.none;
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  final TextEditingController _loginIdController = TextEditingController(
    text: 'ngo.operations@navjeevan.app',
  );
  final TextEditingController _loginPinController = TextEditingController(
    text: 'Agency@123',
  );
  final TextEditingController _registerOrgController =
      TextEditingController(text: 'NavJeevan Care Foundation');
  final TextEditingController _registerNumberController =
      TextEditingController(text: 'RN-2026-104');
  final TextEditingController _registerEmailController =
      TextEditingController(text: 'ngo.operations@navjeevan.app');
  final TextEditingController _registerPasswordController =
      TextEditingController(text: 'Agency@123');

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
    _registerOrgController.dispose();
    _registerNumberController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  bool get _isAuthActionInProgress =>
      _activeAuthAction != _AgencyAuthAction.none;

  Future<void> _runAuthAction(
    Future<void> Function() action,
    _AgencyAuthAction authAction,
  ) async {
    if (_isAuthActionInProgress) {
      return;
    }
    setState(() => _activeAuthAction = authAction);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _activeAuthAction = _AgencyAuthAction.none);
      }
    }
  }

  Future<void> _enterAgencySystem() async {
    final identifier = _loginIdController.text.trim();
    final password = _loginPinController.text.trim();
    if (identifier.isEmpty || password.isEmpty) {
      showErrorBottomPopup(context, 'Enter agency ID/email and PIN.');
      return;
    }

    try {
      await context.read<AuthProvider>().loginWithRoleIdentifier(
        identifier: identifier,
        password: password,
        expectedRole: 'agency',
      );
      if (!mounted) {
        return;
      }
      context.go(NavJeevanRoutes.agencyRequestsDashboard);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorBottomPopup(context, 'Agency login failed: $error');
    }
  }

  Future<void> _continueAgencyWithGoogle() async {
    try {
      await context.read<AuthProvider>().signInWithGoogle(
        expectedRole: 'agency',
      );
      if (!mounted) {
        return;
      }
      context.go(NavJeevanRoutes.agencyRequestsDashboard);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorBottomPopup(context, 'Agency Google login failed: $error');
    }
  }

  Future<void> _registerAgency() async {
    final org = _registerOrgController.text.trim();
    final registrationNo = _registerNumberController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text.trim();

    if (org.isEmpty ||
        registrationNo.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      showErrorBottomPopup(context, 'Fill all registration fields.');
      return;
    }
    if (password.length < 6) {
      showErrorBottomPopup(context, 'Password must be at least 6 characters.');
      return;
    }

    try {
      await context.read<AuthProvider>().registerWithEmail(
        email: email,
        password: password,
        role: 'agency',
        profile: {
          'organizationName': org,
          'registrationNumber': registrationNo,
        },
      );
      if (!mounted) {
        return;
      }
      context.go(NavJeevanRoutes.agencyRequestsDashboard);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorBottomPopup(context, 'Registration failed: $error');
    }
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
                      color: ParentThemeColors.primaryBlue.withValues(
                        alpha: 0.12,
                      ),
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
                        color: ParentThemeColors.primaryBlue.withValues(
                          alpha: 0.14,
                        ),
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
    final isActionRunning =
        context.watch<AuthProvider>().isLoading || _isAuthActionInProgress;
    final isLoginLoading = _activeAuthAction == _AgencyAuthAction.login;
    final isGoogleLoading = _activeAuthAction == _AgencyAuthAction.google;
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
                labelText: 'Registration Number / Email',
                hintText: 'Enter NGO registration number or official email',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _loginPinController,
              obscureText: _obscureLoginPassword,
              decoration: InputDecoration(
                labelText: 'Password / PIN',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureLoginPassword = !_obscureLoginPassword;
                    });
                  },
                  icon: Icon(
                    _obscureLoginPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoginLoading
                    ? null
                    : () {
                        if (isActionRunning) return;
                        _runAuthAction(
                          _enterAgencySystem,
                          _AgencyAuthAction.login,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ParentThemeColors.primaryBlue,
                  foregroundColor: ParentThemeColors.pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isLoginLoading
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
                    : const Text('Login to Agency Dashboard'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isGoogleLoading
                    ? null
                    : () {
                        if (isActionRunning) return;
                        _runAuthAction(
                          _continueAgencyWithGoogle,
                          _AgencyAuthAction.google,
                        );
                      },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: ParentThemeColors.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                icon: isGoogleLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.g_mobiledata_rounded, size: 24),
                label: Text(
                  isGoogleLoading ? 'Please wait...' : 'Continue with Google',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterCard() {
    final isActionRunning =
        context.watch<AuthProvider>().isLoading || _isAuthActionInProgress;
    final isRegisterLoading = _activeAuthAction == _AgencyAuthAction.register;
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
            TextField(
              controller: _registerOrgController,
              decoration: const InputDecoration(
                labelText: 'Organization Name',
                prefixIcon: Icon(Icons.corporate_fare_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _registerNumberController,
              decoration: const InputDecoration(
                labelText: 'Registration Number',
                prefixIcon: Icon(Icons.verified_user_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _registerEmailController,
              decoration: const InputDecoration(
                labelText: 'Official Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _registerPasswordController,
              obscureText: _obscureRegisterPassword,
              decoration: InputDecoration(
                labelText: 'Set Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureRegisterPassword = !_obscureRegisterPassword;
                    });
                  },
                  icon: Icon(
                    _obscureRegisterPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isRegisterLoading
                    ? null
                    : () {
                        if (isActionRunning) return;
                        _runAuthAction(
                          _registerAgency,
                          _AgencyAuthAction.register,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ParentThemeColors.primaryBlue,
                  foregroundColor: ParentThemeColors.pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isRegisterLoading
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
                    : const Text('Register & Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
