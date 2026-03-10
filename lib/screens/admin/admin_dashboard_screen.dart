import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/logout_button.dart';
import 'widgets/analytics_tab.dart';
import 'widgets/verification_tab.dart';
import 'widgets/ai_risk_tab.dart';
import 'widgets/reports_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  void _navigateToHostTab(int index, {bool closeDrawer = true}) {
    if (!mounted) return;
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
    if (closeDrawer && (_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  final List<Widget> _tabs = [
    const AnalyticsTab(),
    const VerificationTab(),
    const AIRiskTab(),
    const ReportsTab(),
  ];

  final List<String> _titles = [
    'Pune Admin Analytics',
    'Family Verification',
    'AI Risk Prediction',
    'Reports & Compliance',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: NavJeevanColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: NavJeevanColors.pureWhite,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _titles[_selectedIndex],
          style: NavJeevanTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: NavJeevanColors.textDark,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: NavJeevanColors.textDark,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: NavJeevanColors.textDark,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new admin alerts at the moment.'),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          const LogoutButton(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: NavJeevanColors.borderColor.withValues(alpha: 0.3),
            height: 1,
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: NavJeevanColors.primaryRose.withValues(alpha: 0.05),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: NavJeevanColors.primaryRose,
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'System Admin',
                      style: NavJeevanTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded),
              title: const Text('Analytics Overview'),
              onTap: () => _navigateToHostTab(0),
            ),
            ListTile(
              leading: const Icon(Icons.verified_user_rounded),
              title: const Text('Family Verification'),
              onTap: () => _navigateToHostTab(1),
            ),
            ListTile(
              leading: const Icon(Icons.psychology_rounded),
              title: const Text('AI Risk Prediction'),
              onTap: () => _navigateToHostTab(2),
            ),
            ListTile(
              leading: const Icon(Icons.description_rounded),
              title: const Text('Reports & Compliance'),
              onTap: () => _navigateToHostTab(3),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('System Settings'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('System settings module coming soon.'),
                  ),
                );
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => context.go(NavJeevanRoutes.roleSelect),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildHostSwitchChips(),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _tabs),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: NavJeevanColors.pureWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => _navigateToHostTab(index, closeDrawer: false),
          type: BottomNavigationBarType.fixed,
          backgroundColor: NavJeevanColors.pureWhite,
          selectedItemColor: NavJeevanColors.primaryRose,
          unselectedItemColor: NavJeevanColors.textSoft,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              activeIcon: Icon(Icons.bar_chart_rounded, fill: 1.0),
              label: 'ANALYTICS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.verified_user_outlined),
              activeIcon: Icon(Icons.verified_user_rounded),
              label: 'VERIFICATION',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_outlined),
              activeIcon: Icon(Icons.psychology_rounded),
              label: 'AI RISK',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description_rounded),
              label: 'REPORTS',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostSwitchChips() {
    final items = [
      (label: 'Analytics', icon: Icons.bar_chart_rounded),
      (label: 'Verification', icon: Icons.verified_user_rounded),
      (label: 'Risk Analysis', icon: Icons.psychology_rounded),
      (label: 'Reports', icon: Icons.description_rounded),
    ];

    return Container(
      width: double.infinity,
      color: NavJeevanColors.pureWhite,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(items.length, (index) {
            final active = _selectedIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: active,
                onSelected: (_) =>
                    _navigateToHostTab(index, closeDrawer: false),
                avatar: Icon(
                  items[index].icon,
                  size: 16,
                  color: active
                      ? NavJeevanColors.primaryRose
                      : NavJeevanColors.textSoft,
                ),
                label: Text(items[index].label),
                selectedColor: NavJeevanColors.primaryRose.withValues(
                  alpha: 0.12,
                ),
                backgroundColor: NavJeevanColors.backgroundLight,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? NavJeevanColors.primaryRose
                      : NavJeevanColors.textSoft,
                ),
                side: BorderSide(
                  color: active
                      ? NavJeevanColors.primaryRose.withValues(alpha: 0.35)
                      : NavJeevanColors.borderColor.withValues(alpha: 0.4),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
