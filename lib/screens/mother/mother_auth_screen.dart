import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

class MotherAuthScreen extends StatefulWidget {
  const MotherAuthScreen({super.key});

  @override
  State<MotherAuthScreen> createState() => _MotherAuthScreenState();
}

class _MotherAuthScreenState extends State<MotherAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _loginPhoneController = TextEditingController(
    text: '9876543210',
  );
  final TextEditingController _loginPinController = TextEditingController(
    text: '1234',
  );

  final TextEditingController _registerNameController = TextEditingController(
    text: 'Anita Sharma',
  );
  final TextEditingController _registerPhoneController = TextEditingController(
    text: '9876543210',
  );
  final TextEditingController _registerLocationController =
      TextEditingController(text: 'Hadapsar, Pune');

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
    _registerNameController.dispose();
    _registerPhoneController.dispose();
    _registerLocationController.dispose();
    super.dispose();
  }

  void _continueToMotherFlow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Welcome. Moving to mother support dashboard.'),
      ),
    );
    context.go(NavJeevanRoutes.motherHelpRequest);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mother Access'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: NavJeevanColors.bgGradient),
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
                    color: NavJeevanColors.petalLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: NavJeevanColors.borderColor),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      gradient: NavJeevanColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    dividerColor: Colors.transparent,
                    labelPadding: const EdgeInsets.symmetric(vertical: 10),
                    labelColor: NavJeevanColors.pureWhite,
                    unselectedLabelColor: NavJeevanColors.textSoft,
                    labelStyle: NavJeevanTextStyles.labelLarge,
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
        gradient: NavJeevanColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NavJeevanColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: NavJeevanColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.favorite_outline,
              color: NavJeevanColors.pureWhite,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safe & Private Access',
                  style: NavJeevanTextStyles.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  'Login or create profile to continue support services.',
                  style: NavJeevanTextStyles.bodySmall,
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
        color: NavJeevanColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NavJeevanColors.borderColor),
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
    return _buildAuthCard(
      children: [
        Text('Secure Login', style: NavJeevanTextStyles.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Use your registered mobile number and PIN to continue.',
          style: NavJeevanTextStyles.bodySmall,
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _loginPhoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter 10-digit number',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _loginPinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '4-digit PIN',
            hintText: 'Enter secure PIN',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: NavJeevanColors.blush.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NavJeevanColors.borderColor),
          ),
          child: Text(
            'Demo credentials: 9876543210 • 1234',
            style: NavJeevanTextStyles.bodySmall.copyWith(
              color: NavJeevanColors.textMid,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _continueToMotherFlow,
            child: const Text('Login & Continue'),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterCard() {
    return _buildAuthCard(
      children: [
        Text('Quick Registration', style: NavJeevanTextStyles.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Create your profile to access legal, counseling, and NGO support.',
          style: NavJeevanTextStyles.bodySmall,
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _registerNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _registerPhoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter 10-digit number',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _registerLocationController,
          decoration: const InputDecoration(
            labelText: 'Current Location',
            hintText: 'City / Area',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _continueToMotherFlow,
            child: const Text('Register & Continue'),
          ),
        ),
      ],
    );
  }
}
