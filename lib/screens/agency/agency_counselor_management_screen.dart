import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/dummy_agency_data.dart';
import '../../core/constants/route_names.dart';
import '../../core/services/agency_notification_center.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/parent_colors.dart';

class AgencyCounselorManagementScreen extends StatefulWidget {
  const AgencyCounselorManagementScreen({super.key});

  @override
  State<AgencyCounselorManagementScreen> createState() =>
      _AgencyCounselorManagementScreenState();
}

class _AgencyCounselorManagementScreenState
    extends State<AgencyCounselorManagementScreen> {
  final AgencyNotificationCenter _notifications =
      AgencyNotificationCenter.instance;
  String _tab = 'Active';

  Color _availabilityIndicatorColor(Counsellor counselor) {
    if (counselor.status == 'on_leave') return const Color(0xFF3B82F6);
    if (counselor.status == 'full') return const Color(0xFFF59E0B);
    return const Color(0xFF22C55E);
  }

  void _updateCounselorStatus(Counsellor counselor, String newStatus) {
    final statusMap = {
      'available': 'Available',
      'full': 'Full',
      'on_leave': 'On Leave',
    };

    // Update Firestore
    FirebaseService.instance.updateCounselorStatus(
      counselorEmail: counselor.email ?? 'unknown@email.com',
      status: newStatus,
    );

    _notifications.push(
      title: 'Status Updated',
      message: '${counselor.name} marked as ${statusMap[newStatus]}',
      category: 'Counselors',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${counselor.name} marked as ${statusMap[newStatus]}'),
        backgroundColor: ParentThemeColors.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );

    if (mounted) setState(() {});
  }

  void _showCounselorDetailsModal(Counsellor counselor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        maxChildSize: 0.9,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: ParentThemeColors.pureWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Counselor Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ParentThemeColors.backgroundLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Profile section
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(counselor.image),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          counselor.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          counselor.specialty,
                          style: const TextStyle(
                            fontSize: 13,
                            color: ParentThemeColors.textMid,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (counselor.rating != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Color(0xFFFAAC15),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${counselor.rating} • ${counselor.yearsExperience} yrs',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Contact section
              _buildDetailSection('Contact Information', [
                if (counselor.email != null)
                  _buildDetailItem('Email', counselor.email!),
                if (counselor.phone != null)
                  _buildDetailItem('Phone', counselor.phone!),
              ]),
              const SizedBox(height: 20),
              // Professional section
              _buildDetailSection('Professional Details', [
                if (counselor.qualification != null)
                  _buildDetailItem('Qualification', counselor.qualification!),
                if (counselor.yearsExperience != null)
                  _buildDetailItem(
                    'Experience',
                    '${counselor.yearsExperience} years',
                  ),
                if (counselor.bio != null)
                  _buildDetailItem('Bio', counselor.bio!, isMultiline: true),
              ]),
              // Certifications section
              if (counselor.certifications != null &&
                  counselor.certifications!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Certifications',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: ParentThemeColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: counselor.certifications!.map((cert) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E7FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(
                                0xFF4F46E5,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            cert,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              // Languages section
              if (counselor.languages != null &&
                  counselor.languages!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Languages',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: ParentThemeColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      counselor.languages!.join(', '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: ParentThemeColors.textMid,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateCounselorStatus(counselor, 'available');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Mark Available'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateCounselorStatus(counselor, 'on_leave');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('On Leave'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: ParentThemeColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        ...items,
      ],
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: ParentThemeColors.textMid,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: ParentThemeColors.textDark,
              height: 1.4,
            ),
            maxLines: isMultiline ? 4 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final counselors =
        DummyAgencyData.agencyCounsellors
            .where(
              (c) => _tab == 'Active'
                  ? c.status == 'available'
                  : _tab == 'Full'
                  ? c.status == 'full'
                  : _tab == 'On Leave'
                  ? c.status == 'on_leave'
                  : false,
            )
            .toList()
          ..sort((a, b) {
            final aLoad = a.activeCases / a.maxCases;
            final bLoad = b.activeCases / b.maxCases;
            return aLoad.compareTo(bLoad);
          });

    return Scaffold(
      backgroundColor: ParentThemeColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStats(),
                  const SizedBox(height: 14),
                  const Text(
                    'AVAILABLE PROFESSIONALS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: ParentThemeColors.textMid,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (counselors.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ParentThemeColors.pureWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ParentThemeColors.borderColor.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Text(
                        'No counselors in $_tab status.',
                        style: const TextStyle(
                          color: ParentThemeColors.textMid,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    ...counselors.map(_buildCounselorCard),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        border: Border(
          bottom: BorderSide(
            color: ParentThemeColors.borderColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          const Text(
            'Counselor Directory',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Active', 'Full', 'On Leave'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        border: Border(
          bottom: BorderSide(
            color: ParentThemeColors.borderColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: tabs.map((tab) {
          final selected = _tab == tab;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _tab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected
                          ? const Color(0xFFEC5B13)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                    color: selected
                        ? const Color(0xFFEC5B13)
                        : ParentThemeColors.textMid,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStats() {
    final active = DummyAgencyData.agencyCounsellors
        .where((c) => c.status == 'available')
        .length;
    final avgLoad =
        DummyAgencyData.agencyCounsellors
            .map((c) => c.activeCases / c.maxCases)
            .reduce((a, b) => a + b) /
        DummyAgencyData.agencyCounsellors.length;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x330EA5E9)),
            ),
            child: Column(
              children: [
                const Text(
                  'TOTAL ACTIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0EA5E9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$active',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE7F3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x33DB2777)),
            ),
            child: Column(
              children: [
                const Text(
                  'AVG CASELOAD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDB2777),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(avgLoad * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounselorCard(Counsellor counselor) {
    final full = counselor.activeCases >= counselor.maxCases;
    final percentage = (counselor.activeCases / counselor.maxCases * 100)
        .toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ParentThemeColors.borderColor.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row with profile and quick actions
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: ParentThemeColors.borderColor.withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      image: DecorationImage(
                        image: NetworkImage(counselor.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _availabilityIndicatorColor(counselor),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ParentThemeColors.pureWhite,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            counselor.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (counselor.rating != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 12,
                                color: Color(0xFFFAAC15),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${counselor.rating}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    Text(
                      counselor.specialty,
                      style: const TextStyle(
                        fontSize: 11,
                        color: ParentThemeColors.textMid,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (counselor.qualification != null)
                      Text(
                        counselor.qualification!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: ParentThemeColors.textSoft,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Status update menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'details') {
                    _showCounselorDetailsModal(counselor);
                  } else {
                    _updateCounselorStatus(counselor, value);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 'available',
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Mark Available'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'full',
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Mark Full'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'on_leave',
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('On Leave'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ParentThemeColors.backgroundLight,
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: ParentThemeColors.textMid,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Certifications badges (if any)
          if (counselor.certifications != null &&
              counselor.certifications!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 4,
                  children: counselor.certifications!.take(2).map((cert) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        cert,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],
            ),
          // Availability and caseload row
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 12,
                color: Color(0xFF0EA5E9),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  counselor.availabilityDays.join(', '),
                  style: const TextStyle(
                    fontSize: 10,
                    color: ParentThemeColors.textMid,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.group, size: 12, color: Color(0xFFDB2777)),
              const SizedBox(width: 4),
              Text(
                '${counselor.activeCases}/${counselor.maxCases}',
                style: const TextStyle(
                  fontSize: 10,
                  color: ParentThemeColors.textMid,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Caseload progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: counselor.activeCases / counselor.maxCases,
              minHeight: 6,
              color: full ? const Color(0xFFF59E0B) : const Color(0xFFDB2777),
              backgroundColor: const Color(0xFFFCE7F3),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$percentage% load',
              style: const TextStyle(
                fontSize: 9,
                color: ParentThemeColors.textSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
          _navItem('Counselors', Icons.groups, true, () {}),
          _navItem(
            'Profile',
            Icons.person,
            false,
            () => context.go(NavJeevanRoutes.agencyProfile),
          ),
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
                color: active
                    ? const Color(0xFFEC5B13)
                    : ParentThemeColors.textMid,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  color: active
                      ? const Color(0xFFEC5B13)
                      : ParentThemeColors.textMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
