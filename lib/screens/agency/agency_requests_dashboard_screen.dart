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
      _requestStatuses.values.where((status) => status == 'Accepted').length;

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
    final requestId = request['id'] ?? '';
    final currentStatus =
        (_requestStatuses[requestId] ?? request['status'] ?? 'Requested').trim();
    final hasAssignment = (request['assignmentId'] ?? '').trim().isNotEmpty;

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
              if (currentStatus == 'Requested')
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Accept Request'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _updateRequestStatus(request, 'Accepted');
                  },
                ),
              if (hasAssignment &&
                  (currentStatus == 'Accepted' || currentStatus == 'Requested'))
                ListTile(
                  leading: const Icon(Icons.event_available_outlined),
                  title: const Text('Schedule Session'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _openScheduleSessionDialog(request);
                  },
                ),
              if (hasAssignment && currentStatus == 'Scheduled')
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: const Text('Start Session'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _updateRequestStatus(request, 'In Session');
                  },
                ),
              if (hasAssignment && currentStatus == 'In Session')
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Complete Session'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _updateRequestStatus(request, 'Completed');
                  },
                ),
              if (!hasAssignment &&
                  (currentStatus == 'Accepted' ||
                      currentStatus == 'Scheduled' ||
                      currentStatus == 'In Session'))
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Assign counselor to conduct session.'),
                ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: const Text('Mark Declined'),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateRequestStatus(request, 'Declined');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openQuickAssignModal(Map<String, String> request) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ParentThemeColors.pureWhite,
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.instance.watchCounselorDirectory(),
          builder: (context, snapshot) {
            final candidates = (snapshot.data?.docs ?? [])
                .map(
                  (doc) => _counselorFromMap(doc.data() as Map<String, dynamic>),
                )
                .where((c) => c.status == 'available')
                .toList()
              ..sort(
                (a, b) => (a.maxCases == 0 ? 0 : a.activeCases / a.maxCases)
                    .compareTo(
                      b.maxCases == 0 ? 0 : b.activeCases / b.maxCases,
                    ),
              );

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
                  if (candidates.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No available counselors found.'),
                    )
                  else
                    ...candidates.map((counselor) {
                      final loadPercent = counselor.maxCases == 0
                          ? '0'
                          : ((counselor.activeCases / counselor.maxCases) * 100)
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
                        subtitle: Text(
                          '${counselor.specialty} • $loadPercent% load',
                        ),
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
      },
    );
  }

  Counsellor _counselorFromMap(Map<String, dynamic> data) {
    return Counsellor(
      name: (data['name'] ?? 'Counselor').toString(),
      specialty: (data['specialty'] ?? 'Support').toString(),
      availabilityDays: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      activeCases: int.tryParse((data['activeCases'] ?? 0).toString()) ?? 0,
      maxCases: int.tryParse((data['maxCases'] ?? 10).toString()) ?? 10,
      status: (data['status'] ?? 'available').toString(),
      image: (data['image'] ?? 'https://via.placeholder.com/150').toString(),
      action: 'manage',
      email: data['email']?.toString(),
      phone: data['phone']?.toString(),
      qualification: data['qualification']?.toString(),
      rating: double.tryParse((data['rating'] ?? 4.5).toString()),
      yearsExperience: int.tryParse((data['yearsExperience'] ?? 5).toString()),
      certifications: const ['Verified'],
      bio: data['bio']?.toString() ?? 'Professional counselor listed in Firestore.',
      languages: const ['English'],
    );
  }

  Future<void> _assignCounselorToRequest(
    Map<String, String> request,
    Counsellor counselor,
  ) async {
    final requestId = request['id'] ?? '';
    final requestType = request['type'] == 'Mother Counseling' ? 'mother' : 'parent';
    final userId = request['userId'] ?? requestId;
    final supportRequestId = requestType == 'parent' ? requestId : null;

    try {
      final assignmentId = await FirebaseService.instance.assignCounselorToRequest(
        counselorName: counselor.name,
        counselorEmail: counselor.email ?? '',
        requestId: requestId,
        userId: userId,
        requestType: requestType,
        supportRequestId: supportRequestId,
        ngoName: 'Agency Desk',
        assignmentStatus: 'Accepted',
      );

      await FirebaseService.instance.updateCounselorAssignmentLifecycle(
        assignmentId: assignmentId,
        status: 'Accepted',
        actorRole: 'ngo',
        notes: 'Counselor assigned and request accepted by NGO.',
      );

      if (!mounted) return;
      setState(() {
        _assignedCounselorByRequest[requestId] = counselor.name;
        _requestStatuses[requestId] = 'Accepted';
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

  Future<void> _openScheduleSessionDialog(Map<String, String> request) async {
    final assignmentId = (request['assignmentId'] ?? '').trim();
    if (assignmentId.isEmpty) {
      if (!mounted) return;
      showErrorBottomPopup(
        context,
        'Assign a counselor first, then schedule the session.',
      );
      return;
    }

    String selectedMode = 'Video';
    String selectedSlot = '04:00 PM';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final meetingLinkCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final didConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Schedule Session'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Session Mode'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMode,
                      items: const ['Video', 'Audio', 'In-Person']
                          .map((mode) => DropdownMenuItem(
                                value: mode,
                                child: Text(mode),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedMode = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                        );
                        if (picked == null) return;
                        setDialogState(() => selectedDate = picked);
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Time Slot'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSlot,
                      items: const [
                        '09:30 AM',
                        '11:00 AM',
                        '02:30 PM',
                        '04:00 PM',
                        '06:30 PM',
                      ]
                          .map((slot) => DropdownMenuItem(
                                value: slot,
                                child: Text(slot),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedSlot = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: meetingLinkCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Meeting Link (optional)',
                        hintText: 'https://meet.google.com/...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Session Notes',
                        hintText: 'Pre-session notes for parent and counselor',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Schedule'),
                ),
              ],
            );
          },
        );
      },
    );

    if (didConfirm != true) return;

    try {
      await FirebaseService.instance.scheduleCounselorSession(
        assignmentId: assignmentId,
        sessionMode: selectedMode,
        scheduledAt: selectedDate,
        slot: selectedSlot,
        meetingLink: meetingLinkCtrl.text.trim(),
        notes: notesCtrl.text.trim(),
        actorRole: 'ngo',
      );

      if (!mounted) return;
      final requestId = request['id'] ?? '';
      setState(() {
        if (requestId.isNotEmpty) {
          _requestStatuses[requestId] = 'Scheduled';
        }
      });
      _notifications.push(
        title: 'Session Scheduled',
        message:
            '${request['id'] ?? 'Request'} scheduled on ${selectedDate.day}/${selectedDate.month}/${selectedDate.year} at $selectedSlot.',
        category: 'Requests',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session scheduled successfully.'),
          backgroundColor: ParentThemeColors.successGreen,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      showErrorBottomPopup(context, 'Could not schedule session: $error');
    }
  }

  Future<void> _updateRequestStatus(
    Map<String, String> request,
    String status,
  ) async {
    final requestId = request['id'] ?? '';
    final requestType = request['type'] ?? 'Parent Support';
    final assignmentId = request['assignmentId'];
    if ((status == 'In Session' || status == 'Completed') &&
        (assignmentId == null || assignmentId.isEmpty)) {
      if (!mounted) return;
      showErrorBottomPopup(
        context,
        'Assign and schedule counselor session before updating to $status.',
      );
      return;
    }
    final phase = switch (status) {
      'Accepted' => 2,
      'Scheduled' => 3,
      'In Session' => 4,
      'Completed' => 5,
      _ => 1,
    };

    try {
      if (requestType == 'Parent Support') {
        await FirebaseService.instance.updateParentSupportRequestStatus(
          requestId: requestId,
          status: status,
          phase: phase,
          actorRole: 'ngo',
          notes: 'NGO updated parent support request to $status',
        );
      } else {
        await FirebaseService.instance.updateCounselingSupportRequestStatus(
          requestId: requestId,
          status: status,
          actorRole: 'ngo',
          notes: 'NGO updated mother counseling request to $status',
        );
      }

      if (assignmentId != null && assignmentId.isNotEmpty) {
        await FirebaseService.instance.updateCounselorAssignmentLifecycle(
          assignmentId: assignmentId,
          status: status,
          actorRole: 'ngo',
          notes: 'NGO updated assignment to $status',
        );
      }
    } catch (_) {}

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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.instance.watchCounselorDirectory(),
        builder: (context, counselorSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.instance.watchAllCounselingBookings(),
            builder: (context, bookingSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.instance.watchAllCounselingRequests(),
                builder: (context, supportSnap) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseService.instance.watchAllCounselorAssignments(),
                    builder: (context, assignmentSnap) {
                      final counselorDocs = counselorSnap.data?.docs ?? [];
                      final allCounselors = counselorDocs
                          .map(
                            (doc) => _counselorFromMap(
                              doc.data() as Map<String, dynamic>,
                            ),
                          )
                          .toList();

                      return SafeArea(
                        child: Column(
                          children: [
                            Expanded(
                              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                stream: FirebaseService.instance.watchAllParentSupportRequests(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  final parentDocs = snapshot.data?.docs ??
                                      const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                                  final motherDocs = (supportSnap.data?.docs ??
                                          const <QueryDocumentSnapshot<dynamic>>[])
                                      .map((doc) => Map<String, dynamic>.from(doc.data() as Map<String, dynamic>))
                                      .toList();

                                  final assignmentDocs = assignmentSnap.data?.docs ?? [];
                                  final assignmentByRequestId = <String, Map<String, dynamic>>{};
                                  for (final doc in assignmentDocs) {
                                    final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
                                    final rid = (data['requestId'] ?? '').toString();
                                    if (rid.isNotEmpty && !assignmentByRequestId.containsKey(rid)) {
                                      assignmentByRequestId[rid] = data;
                                    }
                                  }

                                  final requestRows = <Map<String, String>>[
                                    ...parentDocs.map((doc) {
                                      final data = doc.data();
                                      final rid = (data['requestId'] ?? doc.id).toString();
                                      final assignment = assignmentByRequestId[rid] ?? <String, dynamic>{};
                                      return {
                                        'id': rid,
                                        'region': (data['region'] ?? 'Unknown').toString(),
                                        'reason': (data['serviceType'] ?? 'Parent Support').toString(),
                                        'risk': (data['riskLevel'] ?? 'Medium').toString(),
                                        'status': (_requestStatuses[rid] ?? data['status'] ?? 'Requested').toString(),
                                        'type': 'Parent Support',
                                        'userId': (data['userId'] ?? '').toString(),
                                        'assignmentId': (assignment['assignmentId'] ?? '').toString(),
                                      };
                                    }),
                                    ...motherDocs.map((data) {
                                      final rid = (data['requestId'] ?? '').toString();
                                      final assignment = assignmentByRequestId[rid] ?? <String, dynamic>{};
                                      return {
                                        'id': rid,
                                        'region': (data['region'] ?? 'Unknown').toString(),
                                        'reason': (data['requestKind'] ?? 'Mother Counseling').toString(),
                                        'risk': (data['riskLevel'] ?? 'Medium').toString(),
                                        'status': (_requestStatuses[rid] ?? data['status'] ?? 'Requested').toString(),
                                        'type': 'Mother Counseling',
                                        'userId': (data['userId'] ?? '').toString(),
                                        'assignmentId': (assignment['assignmentId'] ?? '').toString(),
                                      };
                                    }),
                                  ];

                                  final filteredDocs = requestRows.where((row) {
                                    final risk = (row['risk'] ?? 'Low');
                                    final status = (row['status'] ?? 'Requested');
                                    switch (_selectedFilter) {
                                      case 'Urgent':
                                        return risk == 'High';
                                      case 'In Progress':
                                        return status == 'Accepted' ||
                                            status == 'Scheduled' ||
                                            status == 'In Session';
                                      case 'Resolved':
                                        return status == 'Completed';
                                      default:
                                        return true;
                                    }
                                  }).toList();

                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                        child: _buildWelcomeBanner(requestCount: requestRows.length),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                        child: _buildFilterChips(),
                                      ),
                                      Expanded(
                                        child: ListView(
                                    padding: EdgeInsets.zero,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                        child: _buildRequestHeader(),
                                      ),
                                      if (filteredDocs.isEmpty)
                                        const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(32),
                                            child: Text('No active requests found.'),
                                          ),
                                        )
                                      else
                                        ...filteredDocs.take(20).map(_buildRequestCard),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: _buildStatsTiles(
                                          counselors: allCounselors,
                                          bookingDocs: bookingSnap.data?.docs ?? [],
                                          supportDocs: supportSnap.data?.docs ?? [],
                                          assignmentDocs: assignmentSnap.data?.docs ?? [],
                                        ),
                                      ),
                                    ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
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

  Widget _buildWelcomeBanner({required int requestCount}) {
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
            'You have $requestCount help requests requiring immediate attention today.',
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
    final actionLabel = switch (status) {
      'Accepted' => 'Schedule',
      'Scheduled' => 'Start',
      'In Session' => 'Complete',
      'Completed' => 'View',
      _ => 'Assign',
    };
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
                Text(
                  actionLabel,
                  style: const TextStyle(
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

  Widget _buildStatsTiles({
    required List<Counsellor> counselors,
    required List<QueryDocumentSnapshot> bookingDocs,
    required List<QueryDocumentSnapshot> supportDocs,
    required List<QueryDocumentSnapshot> assignmentDocs,
  }) {
    final activeCounselors = counselors.where((c) => c.status == 'available').length;
    final requestedBookings = bookingDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['status'] ?? 'Requested') == 'Requested';
    }).length;
    final quickSupport = supportDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['status'] ?? 'Requested') == 'Requested';
    }).length;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _statsTile('Active Counselors', '$activeCounselors Online', const Color(0xFFE0F2FE)),
        _statsTile('Resolved Today', '$_resolvedCount Cases', const Color(0xFFFCE7F3)),
        _statsTile('Booking Queue', '$requestedBookings Pending', const Color(0xFFEDE9FE)),
        _statsTile('Support Queue', '$quickSupport Pending', const Color(0xFFECFDF5)),
        _statsTile('Active Assignments', '${assignmentDocs.length} Live', const Color(0xFFFFF7ED)),
      ],
    );
  }

  Widget _statsTile(String title, String value, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
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
