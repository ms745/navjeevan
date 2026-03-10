import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/dummy_agency_data.dart';
import '../../core/constants/route_names.dart';
import '../../core/services/agency_notification_center.dart';
import '../../core/theme/parent_colors.dart';

class AgencyProfileScreen extends StatefulWidget {
  const AgencyProfileScreen({super.key});

  @override
  State<AgencyProfileScreen> createState() => _AgencyProfileScreenState();
}

class _AgencyProfileScreenState extends State<AgencyProfileScreen> {
  final AgencyNotificationCenter _notifications = AgencyNotificationCenter.instance;
  bool _editMode = false;
  late final TextEditingController _nameController;
  late final TextEditingController _regController;
  late final TextEditingController _missionController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _hqController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Global Welfare Alliance Foundation');
    _regController = TextEditingController(text: 'RN-2023-001');
    _missionController = TextEditingController(
      text:
          'Dedicated to providing immediate welfare support and counseling to vulnerable families and mothers.',
    );
    _emailController = TextEditingController(text: 'contact@gwalliance.org');
    _phoneController = TextEditingController(text: '+91 9876543210');
    _hqController = TextEditingController(text: 'Pune, Maharashtra');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regController.dispose();
    _missionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _hqController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentThemeColors.pureWhite,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTopProfile(),
            const SizedBox(height: 20),
            _buildAgencyDetails(),
            const SizedBox(height: 16),
            _buildContactInfo(),
            const SizedBox(height: 16),
            _buildAccessControl(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go(NavJeevanRoutes.roleSelect),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEE2E2),
                foregroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                side: const BorderSide(color: Color(0xFFFECACA)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout from Agency'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: ParentThemeColors.pureWhite,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Agency Settings',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        IconButton(
          icon: Icon(_editMode ? Icons.save : Icons.edit),
          color: const Color(0xFFEC5B13),
          onPressed: () {
            setState(() => _editMode = !_editMode);
            if (!_editMode) {
              _notifications.push(
                title: 'Profile Updated',
                message: 'Agency profile details were saved successfully.',
                category: 'Profile',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Agency profile updated.')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildTopProfile() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F2FE), Color(0xFFFCE7F3)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: ParentThemeColors.primaryBlue,
            child: const Icon(Icons.apartment, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 10),
          const Text(
            'Global Welfare Alliance',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Non-Profit Organization • ID: NGO101',
            style: TextStyle(color: ParentThemeColors.textMid, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAgencyDetails() {
    return _sectionCard(
      title: 'Agency Details',
      children: [
        _field('Registration Name', _nameController),
        _field('Registration Number', _regController),
        _field('Mission Statement', _missionController, maxLines: 3),
      ],
    );
  }

  Widget _buildContactInfo() {
    return _sectionCard(
      title: 'Contact Information',
      children: [
        _field('Public Email', _emailController),
        _field('Support Line', _phoneController),
        _field('Headquarters', _hqController),
      ],
    );
  }

  Widget _buildAccessControl() {
    final members = DummyAgencyData.counselors.take(3).toList();
    return _sectionCard(
      title: 'Access Control',
      children: [
        ...members.map(
          (member) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: ParentThemeColors.skyBlue,
              child: Text(
                member.name.split(' ').map((w) => w[0]).take(2).join(),
                style: const TextStyle(
                  color: ParentThemeColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(member.name),
            subtitle: Text(member.specialty),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ParentThemeColors.primaryBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Editor',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _notifications.push(
              title: 'Team Invite',
              message: 'New member invitation action started.',
              category: 'Profile',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invite flow started for new member.')),
            );
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Invite New Member'),
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ParentThemeColors.borderColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        enabled: _editMode,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: _editMode
              ? ParentThemeColors.pureWhite
              : ParentThemeColors.skyBlue.withValues(alpha: 0.15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        border: Border(
          top: BorderSide(
            color: ParentThemeColors.borderColor.withValues(alpha: 0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          _navItem(
            'Requests',
            Icons.assignment,
            false,
            () => context.go(NavJeevanRoutes.agencyRequestsDashboard),
          ),
          _navItem(
            'Welfare',
            Icons.health_and_safety,
            false,
            () => context.go(NavJeevanRoutes.agencyWelfareMonitoring),
          ),
          _navItem(
            'Counselors',
            Icons.groups,
            false,
            () => context.go(NavJeevanRoutes.agencyCounselorManagement),
          ),
          _navItem('Profile', Icons.person, true, () {}),
        ],
      ),
    );
  }

  Widget _navItem(
    String label,
    IconData icon,
    bool active,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active ? const Color(0xFFEC5B13) : ParentThemeColors.textMid,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  color: active ? const Color(0xFFEC5B13) : ParentThemeColors.textMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
