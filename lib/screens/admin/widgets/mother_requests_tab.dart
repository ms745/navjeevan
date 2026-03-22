import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class MotherRequestsTab extends StatefulWidget {
  const MotherRequestsTab({super.key});

  @override
  State<MotherRequestsTab> createState() => _MotherRequestsTabState();
}

class _MotherRequestsTabState extends State<MotherRequestsTab> {
  String _searchQuery = '';
  String _statusFilter = 'All';

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<String?> _promptDocumentNotes({
    required String title,
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add note for mother (optional)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    return value;
  }

  Future<void> _verifyChildDocument({
    required String requestId,
    required String docKey,
    required String status,
    String? currentNotes,
  }) async {
    final notes = await _promptDocumentNotes(
      title: status == 'Verified'
          ? 'Verification note (optional)'
          : 'What should be updated?',
      initialValue: currentNotes,
    );
    if (notes == null) {
      return;
    }

    await FirebaseService.instance.updateMotherRequestDocumentVerification(
      requestId: requestId,
      docKey: docKey,
      status: status,
      notes: notes,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$docKey marked as $status')),
    );
  }

  final List<String> _statusOptions = const [
    'All',
    'Active',
    'In Process',
    'Accepted',
    'Declined',
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.instance.watchAllRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['requestType'] ?? 'child_surrender') ==
              'child_surrender';
        }).toList();

        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? 'Active').toString();
          final reasons = ((data['reasons'] as List?) ?? const [])
              .join(', ')
              .toLowerCase();
          final region = (data['region'] ?? '').toString().toLowerCase();
          final query = _searchQuery.trim().toLowerCase();
          final matchesSearch =
              query.isEmpty || reasons.contains(query) || region.contains(query);
          final matchesStatus =
              _statusFilter == 'All' || status == _statusFilter;
          return matchesSearch && matchesStatus;
        }).toList()
          ..sort((a, b) {
            final aTime =
                ((a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?)
                    ?.millisecondsSinceEpoch ??
                0;
            final bTime =
                ((b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?)
                    ?.millisecondsSinceEpoch ??
                0;
            return bTime.compareTo(aTime);
          });

        return Column(
          children: [
            _buildSummaryRow(docs),
            _buildControls(filtered.length),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final doc = filtered[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildRequestCard(doc.id, data);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(List<QueryDocumentSnapshot> docs) {
    int countStatus(String status) => docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['status'] ?? 'Active') == status;
        }).length;

    final summaryItems = [
      ('Active', countStatus('Active'), Colors.orange),
      ('In Process', countStatus('In Process'), Colors.blue),
      ('Accepted', countStatus('Accepted'), Colors.green),
      ('Declined', countStatus('Declined'), Colors.red),
    ];

    return Container(
      width: double.infinity,
      color: NavJeevanColors.pureWhite,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: summaryItems.map((item) {
          final label = item.$1;
          final value = item.$2;
          final color = item.$3;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: 8),
                Text(
                  '$label: $value',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildControls(int count) {
    return Container(
      color: NavJeevanColors.pureWhite,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search by reason or region',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: NavJeevanColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusOptions.map((status) {
                      final active = _statusFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: active,
                          onSelected: (_) =>
                              setState(() => _statusFilter = status),
                          selectedColor:
                              NavJeevanColors.primaryRose.withValues(alpha: 0.12),
                          backgroundColor: NavJeevanColors.backgroundLight,
                          labelStyle: TextStyle(
                            color: active
                                ? NavJeevanColors.primaryRose
                                : NavJeevanColors.textSoft,
                            fontWeight: FontWeight.w700,
                          ),
                          side: BorderSide(
                            color: active
                                ? NavJeevanColors.primaryRose
                                : NavJeevanColors.borderColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$count request(s)',
                style: NavJeevanTextStyles.bodySmall.copyWith(
                  color: NavJeevanColors.textSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _statusFilter = 'All';
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: NavJeevanColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NavJeevanColors.borderColor),
        ),
        child: Text(
          'No mother surrender requests found for the selected filters.',
          style: NavJeevanTextStyles.bodyMedium.copyWith(
            color: NavJeevanColors.textSoft,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildRequestCard(String requestId, Map<String, dynamic> data) {
    final status = (data['status'] ?? 'Active').toString();
    final reasons = ((data['reasons'] as List?) ?? const []).join(', ');
    final region = (data['region'] ?? 'Unknown').toString();
    final createdAt = data['createdAt'] as Timestamp?;
    final risk = (data['riskLevel'] ?? 'Low').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NavJeevanColors.pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NavJeevanColors.borderColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  requestId,
                  style: NavJeevanTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoPill(Icons.location_on_outlined, region),
              _infoPill(Icons.warning_amber_rounded, 'Risk: $risk'),
              _infoPill(
                Icons.schedule_outlined,
                createdAt != null ? _formatDate(createdAt.toDate()) : 'Recently',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Reasons',
            style: NavJeevanTextStyles.bodySmall.copyWith(
              color: NavJeevanColors.textSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reasons.isEmpty ? 'No reasons submitted' : reasons,
            style: NavJeevanTextStyles.bodyMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRequestDetails(requestId, data),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRequestDetails(requestId, data),
                  icon: const Icon(Icons.gavel_rounded, size: 18),
                  label: const Text('Open Actions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NavJeevanColors.primaryRose,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: NavJeevanColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: NavJeevanColors.primaryRose),
          const SizedBox(width: 6),
          Text(text, style: NavJeevanTextStyles.bodySmall),
        ],
      ),
    );
  }

  Future<void> _showRequestDetails(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final reasons = ((data['reasons'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList();
        final bool needsCounseling = data['needsCounseling'] == true;
        final bool isAnonymous = data['isAnonymous'] == true;
        final createdAt = data['createdAt'] as Timestamp?;
        final updatedAt = data['updatedAt'] as Timestamp?;
        final childProfile = Map<String, dynamic>.from(
          data['childProfile'] as Map<String, dynamic>? ??
              <String, dynamic>{},
        );
        final childPhoto = Map<String, dynamic>.from(
          data['childPhoto'] as Map<String, dynamic>? ?? <String, dynamic>{},
        );
        final childPhotoUrl = (childPhoto['downloadUrl'] ?? '').toString();
        final childDocuments = Map<String, dynamic>.from(
          data['childDocuments'] as Map<String, dynamic>? ??
              <String, dynamic>{},
        );

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: NavJeevanColors.pureWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Mother Request Details',
                          style: NavJeevanTextStyles.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _detailCard(
                    children: [
                      _detailRow('Request ID', requestId),
                      _detailRow('Current Status', (data['status'] ?? 'Active').toString()),
                      _detailRow('Region', (data['region'] ?? 'Unknown').toString()),
                      _detailRow('Risk Level', (data['riskLevel'] ?? 'Low').toString()),
                      _detailRow('Urgency', ((data['urgencyLevel'] ?? 0).toString())),
                      _detailRow('Preferred Contact', (data['preferredContact'] ?? 'Phone').toString()),
                      _detailRow('Needs Counseling', needsCounseling ? 'Yes' : 'No'),
                      _detailRow('Anonymous', isAnonymous ? 'Yes' : 'No'),
                      _detailRow('Mother User ID', (data['userId'] ?? 'Unknown').toString()),
                      _detailRow(
                        'Created At',
                        createdAt != null ? _formatDate(createdAt.toDate()) : 'Recently',
                      ),
                      _detailRow(
                        'Updated At',
                        updatedAt != null ? _formatDate(updatedAt.toDate()) : 'Recently',
                      ),
                      _detailRow(
                        'Latest Action',
                        (data['latestAction'] ?? 'Request submitted').toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Submitted Reasons',
                    style: NavJeevanTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _detailCard(
                    children: reasons.isEmpty
                        ? [
                            Text(
                              'No reasons submitted',
                              style: NavJeevanTextStyles.bodyMedium,
                            ),
                          ]
                        : reasons
                            .map(
                              (reason) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• '),
                                    Expanded(
                                      child: Text(
                                        reason,
                                        style: NavJeevanTextStyles.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  if (childProfile.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Child Profile',
                      style: NavJeevanTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _detailCard(
                      children: [
                        if (childPhotoUrl.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              childPhotoUrl,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                height: 180,
                                alignment: Alignment.center,
                                color: Colors.grey.shade100,
                                child: const Text('Unable to load child photo'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        _detailRow('Nickname', (childProfile['nickname'] ?? '-').toString()),
                        _detailRow('Age', (childProfile['age'] ?? '-').toString()),
                        _detailRow('Gender', (childProfile['gender'] ?? '-').toString()),
                        _detailRow('Weight', '${(childProfile['weightKg'] ?? '-').toString()} kg'),
                        _detailRow('Height', '${(childProfile['heightCm'] ?? '-').toString()} cm'),
                        _detailRow('Complexion', (childProfile['complexion'] ?? '-').toString()),
                        _detailRow('Blood Group', (childProfile['bloodGroup'] ?? '-').toString()),
                        _detailRow('Health Status', (childProfile['healthStatus'] ?? '-').toString()),
                        _detailRow('Special Features', (childProfile['specialFeatures'] ?? '-').toString()),
                        _detailRow('Medical Notes', (childProfile['medicalNotes'] ?? '-').toString()),
                        _detailRow('Additional Details', (data['additionalDetails'] ?? '-').toString()),
                      ],
                    ),
                  ],
                  if (childDocuments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Child Documents',
                      style: NavJeevanTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _detailCard(
                      children: childDocuments.entries.map((entry) {
                        final document = Map<String, dynamic>.from(
                          entry.value as Map<String, dynamic>? ??
                              <String, dynamic>{},
                        );
                        final url = (document['downloadUrl'] ?? '').toString();
                        final verificationStatus =
                            (document['verificationStatus'] ?? 'Pending')
                                .toString();
                        final verificationNotes =
                            (document['verificationNotes'] ?? '').toString();
                        final storageProvider =
                          (document['storageProvider'] ?? 'unknown').toString();
                        final cloudinaryPublicId =
                          (document['storagePath'] ?? '').toString();
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text((document['type'] ?? entry.key).toString()),
                          subtitle: Text(
                          '${(document['fileName'] ?? 'Document').toString()}\nStorage: $storageProvider${cloudinaryPublicId.isEmpty ? '' : ' • Asset: $cloudinaryPublicId'}\nStatus: $verificationStatus${verificationNotes.isEmpty ? '' : ' • Note: $verificationNotes'}',
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              if (url.isNotEmpty)
                                TextButton(
                                  onPressed: () => _openUrl(url),
                                  child: const Text('Open'),
                                ),
                              TextButton(
                                onPressed: () => _verifyChildDocument(
                                  requestId: requestId,
                                  docKey:
                                      (document['type'] ?? entry.key).toString(),
                                  status: 'Verified',
                                  currentNotes: verificationNotes,
                                ),
                                child: const Text('Verify'),
                              ),
                              TextButton(
                                onPressed: () => _verifyChildDocument(
                                  requestId: requestId,
                                  docKey:
                                      (document['type'] ?? entry.key).toString(),
                                  status: 'Rejected',
                                  currentNotes: verificationNotes,
                                ),
                                child: const Text('Need Update'),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Event Timeline',
                    style: NavJeevanTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseService.instance.watchRequestEvents(requestId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(minHeight: 2),
                        );
                      }
                      final events = snapshot.data!.docs;
                      if (events.isEmpty) {
                        return _detailCard(
                          children: const [
                            Text('No events recorded yet.'),
                          ],
                        );
                      }
                      return _detailCard(
                        children: events.map((doc) {
                          final event = doc.data() as Map<String, dynamic>;
                          final at = event['createdAt'] as Timestamp?;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(top: 5),
                                  decoration: const BoxDecoration(
                                    color: NavJeevanColors.primaryRose,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (event['status'] ?? 'Updated').toString(),
                                        style: NavJeevanTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        (event['notes'] ?? 'No note').toString(),
                                        style: NavJeevanTextStyles.bodySmall,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${(event['actorRole'] ?? 'system').toString()} • ${at != null ? _formatDate(at.toDate()) : 'Recently'}',
                                        style: NavJeevanTextStyles.bodySmall.copyWith(
                                          color: NavJeevanColors.textSoft,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Actions',
                    style: NavJeevanTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await _updateStatus(requestId, 'In Process');
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('In Process'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _updateStatus(requestId, 'Accepted');
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _updateStatus(requestId, 'Declined');
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NavJeevanColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NavJeevanColors.borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: NavJeevanTextStyles.bodySmall.copyWith(
                color: NavJeevanColors.textSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: NavJeevanTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String requestId, String status) async {
    await FirebaseService.instance.updateMotherRequestStatus(
      requestId: requestId,
      status: status,
      actorRole: 'admin',
      notes: 'Admin updated request to $status',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request $requestId updated to $status')),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.green;
      case 'Declined':
        return Colors.red;
      case 'In Process':
        return Colors.orange;
      default:
        return NavJeevanColors.primaryRose;
    }
  }
}
