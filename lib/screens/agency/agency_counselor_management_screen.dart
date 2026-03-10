import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/dummy_agency_data.dart';
import '../../core/constants/route_names.dart';
import '../../core/services/agency_notification_center.dart';
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
    if (counselor.status == 'full') return const Color(0xFFF59E0B);
    final isFull = counselor.activeCases >= counselor.maxCases;
    return isFull ? const Color(0xFFF59E0B) : const Color(0xFF22C55E);
  }

  bool _isActionEnabled(Counsellor counselor) {
    return counselor.status == 'available';
  }

  void _scheduleCounselor(Counsellor counselor, bool isWaitlist) {
    final message = isWaitlist
        ? 'Added ${counselor.name} to waitlist review.'
        : 'Session scheduled with ${counselor.name}.';
    _notifications.push(
      title: 'Counselor Update',
      message: message,
      category: 'Counselors',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ParentThemeColors.successGreen,
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
                  : _tab == 'Pending'
                  ? c.status == 'full'
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
                          color: ParentThemeColors.borderColor.withValues(alpha: 0.4),
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
    final tabs = ['Active', 'On Leave', 'Pending'];
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
    final actionEnabled = _isActionEnabled(counselor);
    final actionLabel = counselor.action;

    return Opacity(
      opacity: full ? 0.78 : 1,
      child: Container(
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
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: ParentThemeColors.borderColor.withValues(alpha: 0.2),
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
                      Text(
                        counselor.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Specialty: ${counselor.specialty}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: ParentThemeColors.textMid,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: actionEnabled
                      ? () => _scheduleCounselor(counselor, full)
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${counselor.name} is currently at full capacity.',
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionEnabled && !full
                        ? const Color(0xFFEC5B13)
                        : ParentThemeColors.borderColor.withValues(alpha: 0.35),
                    foregroundColor: actionEnabled && !full
                        ? ParentThemeColors.pureWhite
                        : ParentThemeColors.textMid,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
                  ),
                ),
                const Icon(Icons.group, size: 12, color: Color(0xFFDB2777)),
                const SizedBox(width: 4),
                Text(
                  '${counselor.activeCases}/${counselor.maxCases} active',
                  style: const TextStyle(
                    fontSize: 10,
                    color: ParentThemeColors.textMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: counselor.activeCases / counselor.maxCases,
                minHeight: 6,
                color: const Color(0xFFDB2777),
                backgroundColor: const Color(0xFFFCE7F3),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Assignment Load: $percentage%',
                style: const TextStyle(
                  fontSize: 10,
                  color: ParentThemeColors.textMid,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
