import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/route_names.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/auth_provider.dart';

// ─── data models ────────────────────────────────────────────────────────────

class _CounselingRecord {
  final String counselor;
  final String type;
  final String date;
  final String status; // 'Completed' | 'Upcoming' | 'Cancelled'
  const _CounselingRecord(this.counselor, this.type, this.date, this.status);
}

class _EmergencyCall {
  final String helpline;
  final String date;
  final String outcome;
  const _EmergencyCall(this.helpline, this.date, this.outcome);
}

class _SurrenderRecord {
  final String refId;
  final String date;
  final String status; // 'Initiated' | 'Under Review' | 'Completed' | 'On Hold'
  const _SurrenderRecord(this.refId, this.date, this.status);
}

class _AlertItem {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  bool dismissed;
  _AlertItem({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    this.dismissed = false,
  });
}

// ─── screen ─────────────────────────────────────────────────────────────────

class MotherProfileScreen extends StatefulWidget {
  const MotherProfileScreen({super.key});

  @override
  State<MotherProfileScreen> createState() => _MotherProfileScreenState();
}

class _MotherProfileScreenState extends State<MotherProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Set<String> _cancellingRequestIds = <String>{};

  bool _notificationsEnabled = true;
  bool _anonymousDefault = true;
  String _selectedLanguage = 'English';

  final List<String> _languages = const [
    'English',
    'हिंदी (Hindi)',
    'मराठी (Marathi)',
    'தமிழ் (Tamil)',
    'తెలుగు (Telugu)',
  ];

  // ── static history (replace with Firestore stream in production) ──────────
  final List<_CounselingRecord> _counseling = const [
    _CounselingRecord(
      'Dr. Sarah Miller',
      'Video Session',
      '06 Mar 2026',
      'Completed',
    ),
    _CounselingRecord(
      'Maya Thompson',
      'Audio Follow-up',
      '01 Mar 2026',
      'Completed',
    ),
    _CounselingRecord(
      'Dr. Priya Desai',
      'In-Person',
      '18 Mar 2026',
      'Upcoming',
    ),
  ];

  final List<_EmergencyCall> _emergencyCalls = const [
    _EmergencyCall('1098 – Childline', '04 Mar 2026', 'Referred to NGO'),
    _EmergencyCall('181 – Women Helpline', '25 Feb 2026', 'Counselor assigned'),
  ];

  final List<_SurrenderRecord> _surrenders = const [
    _SurrenderRecord('CS-20260301-004', '01 Mar 2026', 'Under Review'),
    _SurrenderRecord('CS-20260215-001', '15 Feb 2026', 'Completed'),
  ];

  late final List<_AlertItem> _alerts = [
    _AlertItem(
      title: 'Counseling session tomorrow',
      body: 'Dr. Priya Desai • In-Person • 18 Mar 2026, 11:00 AM',
      icon: Icons.calendar_today_outlined,
      color: NavJeevanColors.primaryRose,
    ),
    _AlertItem(
      title: 'Child Surrender status updated',
      body: 'CS-20260301-004 is now Under Review',
      icon: Icons.update_outlined,
      color: NavJeevanColors.warningOrange,
    ),
    _AlertItem(
      title: 'New legal guidance available',
      body: 'CARA 2022 amendment — read the summary',
      icon: Icons.gavel_outlined,
      color: Colors.teal,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── logout ────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) context.go(NavJeevanRoutes.roleSelect);
    }
  }

  // ─── build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    // Derive display name from email or displayName
    final rawEmail = user?.email ?? 'mother.user@navjeevan.app';
    final displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : _nameFromEmail(rawEmail);
    final location = _locationFromEmail(rawEmail);
    final motherId = 'MTH-${rawEmail.hashCode.abs() % 9000 + 1000}';

    return Scaffold(
      backgroundColor: NavJeevanColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── identity card ────────────────────────────────────────────────
          _buildIdentityCard(displayName, motherId, rawEmail, location),

          // ── tabs ─────────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: NavJeevanColors.primaryRose,
              labelColor: NavJeevanColors.primaryRose,
              unselectedLabelColor: NavJeevanColors.textSoft,
              labelStyle: NavJeevanTextStyles.labelLarge,
              tabs: const [
                Tab(text: 'History'),
                Tab(text: 'Alerts'),
                Tab(text: 'Settings'),
                Tab(text: 'Language'),
              ],
            ),
          ),

          // ── tab views ────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryTab(),
                _buildAlertsTab(),
                _buildSettingsTab(),
                _buildLanguageTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── identity card ──────────────────────────────────────────────────────────
  Widget _buildIdentityCard(
    String name,
    String motherId,
    String email,
    String location,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: NavJeevanColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: NavJeevanColors.primaryRose.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'M',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'ID: $motherId',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (location.isNotEmpty)
                  Text(
                    location,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── history tab ────────────────────────────────────────────────────────────
  Widget _buildHistoryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('Counseling Sessions', Icons.people_outline),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.instance.watchCurrentUserCounselingBookings(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 2),
              );
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return _historyCard(
                icon: Icons.info_outline,
                iconColor: Colors.grey,
                title: 'No counseling records yet',
                subtitle: 'Book a session to see history here',
                status: 'Empty',
                statusColor: Colors.grey,
              );
            }
            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final timestamp = data['sessionDate'] as Timestamp?;
                final date = timestamp != null
                    ? _formatDate(timestamp.toDate())
                    : 'Unknown date';
                return _historyCard(
                  icon: Icons.video_call_outlined,
                  iconColor: NavJeevanColors.primaryRose,
                  title: (data['counselorName'] ?? 'Counselor').toString(),
                  subtitle:
                      '${(data['sessionMode'] ?? 'Session').toString()} • $date • ${(data['slot'] ?? '--').toString()}',
                  status: (data['status'] ?? 'Requested').toString(),
                  statusColor: _statusColor((data['status'] ?? '').toString()),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        _sectionHeader('Emergency Calls', Icons.emergency_outlined),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.instance.watchCurrentUserEmergencyCalls(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 2),
              );
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return _historyCard(
                icon: Icons.info_outline,
                iconColor: Colors.grey,
                title: 'No emergency call logs yet',
                subtitle: 'SOS and helpline activity appears here',
                status: 'Empty',
                statusColor: Colors.grey,
              );
            }
            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final timestamp = data['createdAt'] as Timestamp?;
                return _historyCard(
                  icon: Icons.phone_forwarded_outlined,
                  iconColor: Colors.red,
                  title: (data['helpline'] ?? 'Helpline').toString(),
                  subtitle: timestamp != null
                      ? _formatDate(timestamp.toDate())
                      : 'Recently',
                  status: (data['outcome'] ?? 'Requested').toString(),
                  statusColor: NavJeevanColors.warningOrange,
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        _sectionHeader('Child Surrender Requests', Icons.child_care_outlined),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.instance.watchCurrentUserMotherRequests(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _historyCard(
                icon: Icons.error_outline,
                iconColor: Colors.red,
                title: 'Unable to load surrender requests',
                subtitle: snapshot.error.toString(),
                status: 'Error',
                statusColor: Colors.red,
              );
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 2),
              );
            }
            final docs = [...snapshot.data!.docs]
              ..sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aUpdated =
                    (aData['updatedAt'] as Timestamp?) ??
                    (aData['createdAt'] as Timestamp?);
                final bUpdated =
                    (bData['updatedAt'] as Timestamp?) ??
                    (bData['createdAt'] as Timestamp?);
                final aMs = aUpdated?.millisecondsSinceEpoch ?? 0;
                final bMs = bUpdated?.millisecondsSinceEpoch ?? 0;
                return bMs.compareTo(aMs);
              });
            if (docs.isEmpty) {
              return _historyCard(
                icon: Icons.info_outline,
                iconColor: Colors.grey,
                title: 'No surrender requests yet',
                subtitle: 'Submitted requests will appear here',
                status: 'Empty',
                statusColor: Colors.grey,
              );
            }
            return _buildSurrenderRequestsByStatus(docs);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSurrenderRequestsByStatus(List<QueryDocumentSnapshot> docs) {
    final orderedStatuses = [
      'active',
      'in_process',
      'accepted',
      'declined',
      'cancelled',
      'other',
    ];

    final grouped = {
      for (final status in orderedStatuses) status: <QueryDocumentSnapshot>[],
    };

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final normalized = _normalizeRequestStatus((data['status'] ?? '').toString());
      grouped[normalized]!.add(doc);
    }

    return Column(
      children: [
        _buildSurrenderStatusSummary(grouped),
        const SizedBox(height: 10),
        for (final normalized in orderedStatuses)
          if (grouped[normalized]!.isNotEmpty) ...[
            _statusSectionHeader(
              title: _statusSectionTitle(normalized),
              count: grouped[normalized]!.length,
              color: _statusColor(_statusSectionTitle(normalized)),
            ),
            const SizedBox(height: 8),
            ...grouped[normalized]!.map(_buildSurrenderRequestCard),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _buildSurrenderStatusSummary(
    Map<String, List<QueryDocumentSnapshot>> grouped,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NavJeevanColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Status Summary',
            style: NavJeevanTextStyles.titleLarge.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Accepted/Declined statuses are updated by Admin. Scroll below to see each request card details.',
            style: NavJeevanTextStyles.bodySmall.copyWith(
              color: NavJeevanColors.textSoft,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusSummaryChip('Active', grouped['active']!.length, NavJeevanColors.primaryRose),
              _statusSummaryChip('In Process', grouped['in_process']!.length, NavJeevanColors.warningOrange),
              _statusSummaryChip('Accepted (Admin)', grouped['accepted']!.length, NavJeevanColors.successGreen),
              _statusSummaryChip('Declined (Admin)', grouped['declined']!.length, Colors.red),
              _statusSummaryChip('Cancelled (Mother)', grouped['cancelled']!.length, Colors.red.shade700),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusSummaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSurrenderRequestCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['createdAt'] as Timestamp?;
    final updatedTimestamp = data['updatedAt'] as Timestamp?;
    final status = (data['status'] ?? 'Active').toString();
    final isActive = _normalizeRequestStatus(status) == 'active';
    final isCancelling = _cancellingRequestIds.contains(doc.id);
    final latestAction = (data['latestAction'] ?? 'Request submitted').toString();
    final latestActorRole = (data['latestActorRole'] ?? 'system').toString();
    final childProfile = Map<String, dynamic>.from(
      data['childProfile'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
    final childSummary = [
      (childProfile['age'] ?? '').toString(),
      (childProfile['gender'] ?? '').toString(),
      (childProfile['healthStatus'] ?? '').toString(),
    ].where((value) => value.trim().isNotEmpty).join(' • ');
    final filedText = timestamp != null
        ? 'Filed on ${_formatDate(timestamp.toDate())}'
        : 'Recently filed';
    final updateText = updatedTimestamp != null
        ? _formatDate(updatedTimestamp.toDate())
        : 'Recently';
    final actorLabel = latestActorRole.toLowerCase() == 'admin'
        ? 'Admin'
        : (latestActorRole.toLowerCase() == 'mother' ? 'You' : latestActorRole);

    return _historyCard(
      icon: Icons.assignment_outlined,
      iconColor: Colors.teal,
      title: 'Ref: ${(data['requestId'] ?? doc.id).toString()}',
      subtitle:
          '$filedText${childSummary.isEmpty ? '' : '\nChild: $childSummary'}\nLast update: $updateText • $actorLabel • $latestAction',
      status: status,
      statusColor: _statusColor(status),
      topRightAction: isActive
          ? Column(
              children: [
                TextButton(
                  onPressed: () => _showMotherRequestDetails(doc),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: isCancelling
                      ? null
                      : () => _confirmAndCancelSurrenderRequest(
                            requestId: doc.id,
                            referenceId: (data['requestId'] ?? doc.id).toString(),
                          ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: isCancelling
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            )
          : TextButton(
              onPressed: () => _showMotherRequestDetails(doc),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 28),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _reuploadRequestDocument({
    required String requestId,
    required String docType,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    await FirebaseService.instance.reuploadMotherRequestDocument(
      requestId: requestId,
      docType: docType,
      data: result.files.single.bytes!,
      fileName: result.files.single.name,
    );
  }

  void _showMotherRequestDetails(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final childProfile = Map<String, dynamic>.from(
      data['childProfile'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
    final childPhoto = Map<String, dynamic>.from(
      data['childPhoto'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
    final childDocuments = Map<String, dynamic>.from(
      data['childDocuments'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
    final childDocumentStage =
        (data['childDocumentStage'] ?? 'Pending Child Document Review')
            .toString();
    final childDocumentSummary = Map<String, dynamic>.from(
      data['childDocumentSummary'] as Map<String, dynamic>? ??
          <String, dynamic>{},
    );
    final status = (data['status'] ?? 'Active').toString().toLowerCase();
    final canReupload = !(status.contains('accepted') || status.contains('declined') || status.contains('cancelled'));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Surrender Request Details', style: NavJeevanTextStyles.headlineMedium),
                  ),
                  IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close)),
                ],
              ),
              if ((childPhoto['downloadUrl'] ?? '').toString().isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    (childPhoto['downloadUrl'] ?? '').toString(),
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _detailEntry('Request ID', (data['requestId'] ?? doc.id).toString()),
              _detailEntry('Status', (data['status'] ?? 'Active').toString()),
              _detailEntry('Region', (data['region'] ?? 'Unknown').toString()),
              _detailEntry('Reason', ((data['reasons'] as List?) ?? const []).join(', ')),
              _detailEntry('Urgency', (data['urgencyLevel'] ?? '-').toString()),
              _detailEntry('Preferred Contact', (data['preferredContact'] ?? '-').toString()),
              _detailEntry('Child Document Stage', childDocumentStage),
              _detailEntry(
                'Child Document Progress',
                '${(childDocumentSummary['verifiedCount'] ?? 0)}/${(childDocumentSummary['totalDocuments'] ?? 0)} verified',
              ),
              const SizedBox(height: 12),
              Text('Child Profile', style: NavJeevanTextStyles.titleLarge.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              _detailEntry('Nickname', (childProfile['nickname'] ?? '-').toString()),
              _detailEntry('Age', (childProfile['age'] ?? '-').toString()),
              _detailEntry('Gender', (childProfile['gender'] ?? '-').toString()),
              _detailEntry('Weight', '${(childProfile['weightKg'] ?? '-').toString()} kg'),
              _detailEntry('Height', '${(childProfile['heightCm'] ?? '-').toString()} cm'),
              _detailEntry('Complexion', (childProfile['complexion'] ?? '-').toString()),
              _detailEntry('Blood Group', (childProfile['bloodGroup'] ?? '-').toString()),
              _detailEntry('Health Status', (childProfile['healthStatus'] ?? '-').toString()),
              _detailEntry('Special Features', (childProfile['specialFeatures'] ?? '-').toString()),
              _detailEntry('Medical Notes', (childProfile['medicalNotes'] ?? '-').toString()),
              _detailEntry('Additional Details', (data['additionalDetails'] ?? '-').toString()),
              const SizedBox(height: 12),
              Text('Child Documents', style: NavJeevanTextStyles.titleLarge.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              if (childDocuments.isEmpty)
                const Text('No child documents uploaded yet.')
              else
                ...childDocuments.entries.map((entry) {
                  final document = Map<String, dynamic>.from(entry.value as Map<String, dynamic>? ?? <String, dynamic>{});
                  final url = (document['downloadUrl'] ?? '').toString();
                  final type = (document['type'] ?? entry.key).toString();
                  final verificationStatus =
                      (document['verificationStatus'] ?? 'Pending').toString();
                  final verificationNotes =
                      (document['verificationNotes'] ?? '').toString();
                  final canReuploadDoc =
                      canReupload && verificationStatus != 'Verified';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(type),
                    subtitle: Text(
                      '${(document['fileName'] ?? 'Document').toString()}\nStatus: $verificationStatus${verificationNotes.isEmpty ? '' : ' • Note: $verificationNotes'}',
                    ),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        if (url.isNotEmpty)
                          TextButton(
                            onPressed: () => _openUrl(url),
                            child: const Text('Open'),
                          ),
                        if (canReuploadDoc)
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(sheetContext);
                              await _reuploadRequestDocument(requestId: doc.id, docType: type);
                            },
                            child: const Text('Re-upload'),
                          ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _detailEntry(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: NavJeevanTextStyles.bodySmall)),
          Expanded(child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _statusSectionHeader({
    required String title,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$title ($count)',
          style: NavJeevanTextStyles.titleLarge.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  String _normalizeRequestStatus(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.contains('cancel')) return 'cancelled';
    if (normalized.contains('accept')) return 'accepted';
    if (normalized.contains('declin') || normalized.contains('reject')) {
      return 'declined';
    }
    if (normalized.contains('process') || normalized.contains('review')) {
      return 'in_process';
    }
    if (normalized.contains('active') || normalized.contains('request')) {
      return 'active';
    }
    return 'other';
  }

  String _statusSectionTitle(String normalizedStatus) {
    switch (normalizedStatus) {
      case 'active':
        return 'Active';
      case 'in_process':
        return 'In Process';
      case 'accepted':
        return 'Accepted by Admin';
      case 'declined':
        return 'Declined by Admin';
      case 'cancelled':
        return 'Cancelled by Mother';
      default:
        return 'Other Updates';
    }
  }

  String _formatDate(DateTime dateTime) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = monthNames[dateTime.month - 1];
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year;
    return '$day $month $year';
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('cancel')) {
      return Colors.red;
    }
    if (normalized.contains('accept') || normalized.contains('complete')) {
      return NavJeevanColors.successGreen;
    }
    if (normalized.contains('declin') || normalized.contains('reject')) {
      return Colors.red;
    }
    if (normalized.contains('process') || normalized.contains('review')) {
      return NavJeevanColors.warningOrange;
    }
    if (normalized.contains('active') || normalized.contains('request')) {
      return NavJeevanColors.primaryRose;
    }
    return Colors.grey;
  }

  Widget _counselingTile(_CounselingRecord r) {
    final Color statusColor = r.status == 'Completed'
        ? NavJeevanColors.successGreen
        : r.status == 'Upcoming'
            ? NavJeevanColors.primaryRose
            : Colors.grey;
    return _historyCard(
      icon: Icons.video_call_outlined,
      iconColor: NavJeevanColors.primaryRose,
      title: r.counselor,
      subtitle: '${r.type} • ${r.date}',
      status: r.status,
      statusColor: statusColor,
    );
  }

  Widget _emergencyTile(_EmergencyCall r) {
    return _historyCard(
      icon: Icons.phone_forwarded_outlined,
      iconColor: Colors.red,
      title: r.helpline,
      subtitle: r.date,
      status: r.outcome,
      statusColor: NavJeevanColors.warningOrange,
    );
  }

  Widget _surrenderTile(_SurrenderRecord r) {
    final Color statusColor = r.status == 'Completed'
        ? NavJeevanColors.successGreen
        : r.status == 'Under Review'
            ? NavJeevanColors.warningOrange
            : r.status == 'Initiated'
                ? NavJeevanColors.primaryRose
                : Colors.grey;
    return _historyCard(
      icon: Icons.assignment_outlined,
      iconColor: Colors.teal,
      title: 'Ref: ${r.refId}',
      subtitle: 'Filed on ${r.date}',
      status: r.status,
      statusColor: statusColor,
    );
  }

  Widget _historyCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    Widget? topRightAction,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NavJeevanColors.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: iconColor.withValues(alpha: 0.12),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: NavJeevanTextStyles.titleLarge.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: NavJeevanTextStyles.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (topRightAction != null) topRightAction,
              if (topRightAction != null) const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndCancelSurrenderRequest({
    required String requestId,
    required String referenceId,
  }) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Request?'),
        content: Text(
          'Are you sure you want to cancel request $referenceId? This request cannot be resent or reactivated once cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldCancel != true || !mounted) {
      return;
    }

    setState(() => _cancellingRequestIds.add(requestId));
    try {
      await FirebaseService.instance.updateMotherRequestStatus(
        requestId: requestId,
        status: 'Cancelled',
        actorRole: 'mother',
        actorId: FirebaseService.instance.currentUser?.uid,
        notes: 'Request cancelled by mother. This request cannot be resent.',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request $referenceId cancelled successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel request: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _cancellingRequestIds.remove(requestId));
      }
    }
  }

  // ── alerts tab ────────────────────────────────────────────────────────────
  Widget _buildAlertsTab() {
    final active = _alerts.where((a) => !a.dismissed).toList();
    if (active.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('No active alerts', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: active.length,
      itemBuilder: (context, index) {
        final alert = active[index];
        return Dismissible(
          key: ValueKey(alert.title),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.red),
          ),
          onDismissed: (_) => setState(() => alert.dismissed = true),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: alert.color.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: alert.color.withValues(alpha: 0.12),
                  child: Icon(alert.icon, color: alert.color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: NavJeevanTextStyles.titleLarge.copyWith(
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        alert.body,
                        style: NavJeevanTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── settings tab ──────────────────────────────────────────────────────────
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('Preferences', Icons.tune_outlined),
        const SizedBox(height: 8),
        _settingsCard(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Push notifications'),
                subtitle: const Text('Alerts for sessions, updates, SOS'),
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
                activeColor: NavJeevanColors.primaryRose,
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Anonymous mode by default'),
                subtitle: const Text(
                  'Hide identity when submitting help requests',
                ),
                value: _anonymousDefault,
                onChanged: (v) => setState(() => _anonymousDefault = v),
                activeColor: NavJeevanColors.primaryRose,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionHeader('Account', Icons.manage_accounts_outlined),
        const SizedBox(height: 8),
        _settingsCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              radius: 18,
              child: Icon(Icons.logout, color: Colors.white, size: 18),
            ),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Sign out of NavJeevan'),
            onTap: _logout,
          ),
        ),
      ],
    );
  }

  // ── language tab ──────────────────────────────────────────────────────────
  Widget _buildLanguageTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('App Language', Icons.language_outlined),
        const SizedBox(height: 4),
        Text(
          'Choose the language for displaying content in the app.',
          style: NavJeevanTextStyles.bodySmall,
        ),
        const SizedBox(height: 12),
        _settingsCard(
          child: Column(
            children: _languages.map((lang) {
              final bool selected = lang == _selectedLanguage;
              return Column(
                children: [
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      lang,
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: selected
                            ? NavJeevanColors.primaryRose
                            : NavJeevanColors.textDark,
                      ),
                    ),
                    value: lang,
                    groupValue: _selectedLanguage,
                    activeColor: NavJeevanColors.primaryRose,
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedLanguage = v);
                    },
                  ),
                  if (lang != _languages.last)
                    const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: NavJeevanColors.primaryRose),
        const SizedBox(width: 6),
        Text(title, style: NavJeevanTextStyles.headlineMedium),
      ],
    );
  }

  Widget _settingsCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NavJeevanColors.borderColor),
      ),
      child: child,
    );
  }

  String _nameFromEmail(String email) {
    final local = email.split('@').first;
    // e.g. "mother.9876543210" → extract name from profile if available
    if (local.contains('.')) {
      final parts = local.split('.');
      final candidate = parts.firstWhere(
        (p) => !RegExp(r'^\d+$').hasMatch(p),
        orElse: () => '',
      );
      if (candidate.isNotEmpty) {
        return candidate[0].toUpperCase() + candidate.substring(1);
      }
    }
    return 'Mother User';
  }

  String _locationFromEmail(String email) {
    // Location can be read from Firestore profile in production;
    // using a placeholder until Firestore profile fetch is wired up.
    return '';
  }
}
