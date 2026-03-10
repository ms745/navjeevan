import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/dummy_agency_data.dart';
import '../../core/constants/route_names.dart';
import '../../core/services/agency_notification_center.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/parent_colors.dart';
import '../../core/widgets/error_popup.dart';
import '../../core/widgets/logout_button.dart';

class AgencyRequestsDashboardScreen extends StatefulWidget {
  const AgencyRequestsDashboardScreen({super.key});

  @override
  State<AgencyRequestsDashboardScreen> createState() =>
      _AgencyRequestsDashboardScreenState();
}

class _AgencyRequestsDashboardScreenState
    extends State<AgencyRequestsDashboardScreen> {
  final AgencyNotificationCenter _notifications =
      AgencyNotificationCenter.instance;
  String _selectedFilter = 'All';
  final Map<String, String> _assignedCounselorByRequest = {};
  final Map<String, String> _requestStatuses = {
    for (final r in DummyAgencyData.motherSupportRequests)
      r.requestId: r.status,
    for (final r in DummyAgencyData.adoptionRequests)
      r['requestId']!: r['status']!,
  };

  int get _resolvedCount =>
      _requestStatuses.values.where((status) => status == 'Resolved').length;

  List<Map<String, String>> get _allRequests {
    final motherRequests = DummyAgencyData.motherSupportRequests
        .map(
          (request) => {
            'id': request.requestId,
            'region': request.region,
            'reason': request.reason,
            'risk': request.riskLevel,
            'type': 'Surrender Support',
            'status': _requestStatuses[request.requestId] ?? request.status,
          },
        )
        .toList();

    final adoptionRequests = DummyAgencyData.adoptionRequests
        .map(
          (request) => {
            'id': request['requestId']!,
            'region': request['region']!,
            'reason': '${request['familyName']} Family',
            'risk': request['risk']!,
            'type': request['type']!,
            'status':
                _requestStatuses[request['requestId']!] ?? request['status']!,
          },
        )
        .toList();

    return [...motherRequests, ...adoptionRequests];
  }

  Color _riskColor(String risk) {
    if (risk == 'High') return ParentThemeColors.errorRed;
    if (risk == 'Medium') return ParentThemeColors.warningOrange;
    return ParentThemeColors.successGreen;
  }

  void _openRequestAction(Map<String, String> request) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ParentThemeColors.pureWhite,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.assignment_ind),
                title: const Text('Assign Counselor'),
                onTap: () {
                  Navigator.pop(context);
                  _openQuickAssignModal(request);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Mark In Progress'),
                onTap: () {
                  Navigator.pop(context);
                  _updateRequestStatus(request['id']!, 'In Progress');
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Mark Resolved'),
                onTap: () {
                  Navigator.pop(context);
                  _updateRequestStatus(request['id']!, 'Resolved');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openQuickAssignModal(Map<String, String> request) {
    final candidates =
        DummyAgencyData.agencyCounsellors
            .where((c) => c.status == 'available')
            .toList()
          ..sort(
            (a, b) => (a.activeCases / a.maxCases).compareTo(
              b.activeCases / b.maxCases,
            ),
          );

    showModalBottomSheet(
      context: context,
      backgroundColor: ParentThemeColors.pureWhite,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Text(
                'Quick Assign Counselor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ParentThemeColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              ...candidates.map((counselor) {
                final loadPercent =
                    ((counselor.activeCases / counselor.maxCases) * 100)
                        .toStringAsFixed(0);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(counselor.image),
                  ),
                  title: Text(
                    counselor.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('${counselor.specialty} • $loadPercent% load'),
                  trailing: TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _assignCounselorToRequest(request, counselor);
                    },
                    child: const Text('Assign'),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _assignCounselorToRequest(
    Map<String, String> request,
    Counsellor counselor,
  ) async {
    final requestId = request['id'] ?? '';
    final requestType = request['type'] == 'Surrender Support'
        ? 'mother'
        : 'parent';
    final userId = request['userId'] ?? requestId;

    try {
      await FirebaseService.instance.assignCounselorToRequest(
        counselorName: counselor.name,
        counselorEmail: counselor.email ?? '',
        requestId: requestId,
        userId: userId,
        requestType: requestType,
      );

      if (!mounted) return;
      setState(() {
        _assignedCounselorByRequest[requestId] = counselor.name;
        _requestStatuses[requestId] = 'Assigned';
      });
      _notifications.push(
        title: 'Counselor Assigned',
        message: '${counselor.name} assigned to request $requestId.',
        category: 'Requests',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${counselor.name} assigned successfully.'),
          backgroundColor: ParentThemeColors.successGreen,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      showErrorBottomPopup(context, 'Failed to assign counselor.');
    }
  }

  void _updateRequestStatus(String requestId, String status) {
    setState(() {
      _requestStatuses[requestId] = status;
    });
    _notifications.push(
      title: 'Request Updated',
      message: '$requestId status changed to $status.',
      category: 'Requests',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$requestId updated: $status'),
        backgroundColor: ParentThemeColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentThemeColors.pureWhite,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildWelcomeBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: _buildFilterChips(),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.instance.watchAllRequests(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: _buildRequestHeader(),
                      ),
                      if (docs.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No active requests found.'),
                          ),
                        )
                      else
                        ...docs.take(10).map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildRequestCard({
                            'id': doc.id,
                            'region': data['region'] ?? 'Unknown',
                            'reason':
                                (data['reasons'] as List?)?.join(', ') ??
                                'No reason',
                            'risk': data['riskLevel'] ?? 'Low',
                            'status': data['status'] ?? 'Pending',
                            'type': data.containsKey('familyName')
                                ? 'Adoption Support'
                                : 'Surrender Support',
                            'userId': data['userId'] ?? doc.id,
                          });
                        }),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildStatsTiles(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildRequestHeader() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            'ID',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ParentThemeColors.textMid,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'Region',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ParentThemeColors.textMid,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'Reason',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ParentThemeColors.textMid,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Risk',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ParentThemeColors.textMid,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Status',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ParentThemeColors.textMid,
            ),
          ),
        ),
        Expanded(flex: 1, child: SizedBox.shrink()),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: ParentThemeColors.pureWhite,
      surfaceTintColor: Colors.transparent,
      leading: Container(),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEC5B13).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.people, color: Color(0xFFEC5B13), size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ParentThemeColors.textDark,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: ParentThemeColors.textMid),
          onPressed: () {},
        ),
        AnimatedBuilder(
          animation: _notifications,
          builder: (context, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: ParentThemeColors.textMid,
                  ),
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
                        color: Color(0xFFEC5B13),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
        const LogoutButton(),
      ],
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE0F2FE), Color(0xFFFCE7F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back, Sarah',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ParentThemeColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have ${_allRequests.length} help requests from mothers requiring immediate attention today.',
            style: const TextStyle(
              fontSize: 13,
              color: ParentThemeColors.textMid,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Urgent', 'In Progress', 'Resolved'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              selectedColor: ParentThemeColors.primaryBlue,
              labelStyle: TextStyle(
                color: selected
                    ? ParentThemeColors.pureWhite
                    : ParentThemeColors.textDark,
                fontWeight: FontWeight.w700,
              ),
              onSelected: (_) => setState(() => _selectedFilter = filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, String> request) {
    final risk = request['risk']!;
    final requestId = request['id']!;
    final status =
        _requestStatuses[requestId] ?? request['status'] ?? 'Pending';
    final assignedName = _assignedCounselorByRequest[requestId];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          Expanded(
            flex: 2,
            child: Text(
              request['id']!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ParentThemeColors.textDark,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              request['region']!,
              style: const TextStyle(
                fontSize: 13,
                color: ParentThemeColors.textMid,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              request['reason']!,
              style: const TextStyle(
                fontSize: 13,
                color: ParentThemeColors.textMid,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _riskColor(risk).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                risk,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _riskColor(risk),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'Assigned'
                        ? ParentThemeColors.infoBlue.withValues(alpha: 0.15)
                        : ParentThemeColors.borderColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: status == 'Assigned'
                          ? ParentThemeColors.infoBlue
                          : ParentThemeColors.textMid,
                    ),
                  ),
                ),
                if (assignedName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      assignedName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: ParentThemeColors.textMid,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _openRequestAction(request),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Assign',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEC5B13),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFFEC5B13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTiles() {
    final activeCounselors = DummyAgencyData.counselors
        .where((c) => c.status == 'Active')
        .length;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('Active Counselors'),
                const SizedBox(height: 4),
                Text(
                  '$activeCounselors Online',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
            ),
            child: Column(
              children: [
                const Text('Resolved Today'),
                const SizedBox(height: 4),
                Text(
                  '$_resolvedCount Cases',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
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
          _navItem('Requests', Icons.assignment, true, () {}),
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
