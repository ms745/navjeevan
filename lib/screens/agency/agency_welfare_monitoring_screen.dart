import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/dummy_agency_data.dart';
import '../../core/constants/route_names.dart';
import '../../core/services/agency_notification_center.dart';
import '../../core/theme/parent_colors.dart';

class AgencyWelfareMonitoringScreen extends StatefulWidget {
  const AgencyWelfareMonitoringScreen({super.key});

  @override
  State<AgencyWelfareMonitoringScreen> createState() =>
      _AgencyWelfareMonitoringScreenState();
}

class _AgencyWelfareMonitoringScreenState
    extends State<AgencyWelfareMonitoringScreen> {
  final AgencyNotificationCenter _notifications =
      AgencyNotificationCenter.instance;
  String _filter = 'All Cases';
  String _searchQuery = '';

  bool _isRecentUpdate(String lastHomeVisit) {
    final normalized = lastHomeVisit.toLowerCase();
    return normalized.contains('today') || normalized.contains('day');
  }

  bool _matchesFilter(AgencyChildWelfare entry) {
    if (_filter == 'High Risk') {
      return entry.welfareScore < 70;
    }
    if (_filter == 'Updates') {
      return _isRecentUpdate(entry.lastHomeVisit);
    }
    return true;
  }

  Color _scoreColor(int score) {
    if (score < 60) return const Color(0xFFdb2777); // Pink for low
    if (score < 80) return const Color(0xFFF59E0B); // Amber for medium
    return ParentThemeColors.primaryBlue; // Blue for high
  }

  @override
  Widget build(BuildContext context) {
    final data = DummyAgencyData.childWelfare.where(_matchesFilter).where((
      entry,
    ) {
      if (_searchQuery.trim().isEmpty) return true;
      final query = _searchQuery.trim().toLowerCase();
      return entry.childId.toLowerCase().contains(query) ||
          entry.adoptedBy.toLowerCase().contains(query) ||
          entry.region.toLowerCase().contains(query);
    }).toList();
    final highRiskCount = data.where((entry) => entry.welfareScore < 70).length;

    return Scaffold(
      backgroundColor: ParentThemeColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTopFilters(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Active Cases',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: ParentThemeColors.primaryBlue.withValues(alpha: 
                            0.12,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${data.length} Total',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (data.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ParentThemeColors.pureWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ParentThemeColors.borderColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        'No cases found for this filter.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: ParentThemeColors.textMid,
                        ),
                      ),
                    )
                  else
                    ...data.map((entry) => _buildWelfareCard(entry)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: highRiskCount > 0
                          ? ParentThemeColors.errorRed.withValues(alpha: 0.08)
                          : ParentThemeColors.successGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      highRiskCount > 0
                          ? '$highRiskCount child welfare cases need immediate follow-up.'
                          : 'All monitored children are currently stable.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
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
      color: ParentThemeColors.pureWhite,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          const Text(
            'Welfare Monitoring',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _notifications,
            builder: (context, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => showAgencyNotificationsSheet(context),
                  ),
                  if (_notifications.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: ParentThemeColors.errorRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopFilters() {
    final filters = ['All Cases', 'High Risk', 'Updates'];
    return Container(
      color: ParentThemeColors.pureWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final selected = _filter == filter;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _filter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected
                          ? ParentThemeColors.primaryBlue
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  filter,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected
                        ? ParentThemeColors.primaryBlue
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

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Search Child ID or Family',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: ParentThemeColors.pureWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildWelfareCard(AgencyChildWelfare entry) {
    final scoreColor = _scoreColor(entry.welfareScore);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar placeholder
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ParentThemeColors.borderColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    entry.childId.replaceAll('#', '').substring(0, 1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Child ID: ${entry.childId}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ParentThemeColors.textMid,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Assigned: ${entry.adoptedBy}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ParentThemeColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.welfareScore}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: scoreColor,
                      fontSize: 28,
                    ),
                  ),
                  Text(
                    'Welfare Score',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: entry.welfareScore / 100,
              minHeight: 8,
              valueColor: AlwaysStoppedAnimation(scoreColor),
              backgroundColor: scoreColor.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last visit: ${entry.lastHomeVisit}',
                style: const TextStyle(
                  fontSize: 12,
                  color: ParentThemeColors.textMid,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.welfareScore < 70 ? 'Action Required' : 'View Profile',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
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
          _navItem('Welfare', Icons.health_and_safety, true, () {}),
          _navItem(
            'Counselors',
            Icons.groups,
            false,
            () => context.go(NavJeevanRoutes.agencyCounselorManagement),
          ),
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
