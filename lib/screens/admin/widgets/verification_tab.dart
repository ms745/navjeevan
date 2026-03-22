import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class VerificationTab extends StatefulWidget {
  const VerificationTab({super.key});

  @override
  State<VerificationTab> createState() => _VerificationTabState();
}

class _VerificationTabState extends State<VerificationTab> {
  int _activeTab = 0;
  String _searchQuery = '';
  bool _urgentOnly = false;
  bool _newestFirst = true;
  bool _finalApprovalOnly = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.instance.getVerificationQueue(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final cases = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final createdAt =
              data['submittedAt'] as Timestamp? ??
              data['createdAt'] as Timestamp?;
          final summary = Map<String, dynamic>.from(
            data['verificationSummary'] as Map<String, dynamic>? ??
                <String, dynamic>{},
          );
          final documentMap = Map<String, dynamic>.from(
            data['documents'] as Map<String, dynamic>? ?? <String, dynamic>{},
          );
          final status = (data['adoptionStatus'] ?? 'Under Review').toString();
          final stage = (data['verificationStage'] ?? 'Pending Document Review')
              .toString();
          final verifiedCount = (summary['verifiedCount'] ?? 0) as int;
          final totalDocuments =
              (summary['totalDocuments'] ?? documentMap.length) as int;

          return _VerificationCase(
            id: doc.id,
            family: (data['familyName'] ?? 'Unknown family').toString(),
            time: createdAt != null
                ? DateFormat('MMM d, HH:mm').format(createdAt.toDate())
                : 'Recently',
            priority: verifiedCount == totalDocuments && totalDocuments > 0
                ? 'Ready for approval'
                : (verifiedCount > 0 ? 'In progress' : 'New submission'),
            location: (data['region'] ?? 'Unknown location').toString(),
            documentsLabel: '$verifiedCount / $totalDocuments verified',
            status: status,
            verificationStage: stage,
            isUrgent:
                status == 'Changes Requested' ||
                ((summary['pendingCount'] ?? 0) as int) > 0,
            submittedOrder: createdAt?.millisecondsSinceEpoch ?? 0,
            canFinalApprove:
                (summary['allDocumentsVerified'] ?? false) == true &&
                status != 'Verified',
            documents: documentMap,
          );
        }).toList();

        final filtered = _applyFilters(cases);

        return Column(
          children: [
            _buildTabs(cases),
            _buildFilterChips(),
            _buildSearchAndActions(filtered),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: NavJeevanColors.pureWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: NavJeevanColors.borderColor.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Text(
                        'No parent applications found for the current filters.',
                        style: NavJeevanTextStyles.bodyMedium.copyWith(
                          color: NavJeevanColors.textSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    ...filtered.map(_buildFamilyCard),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<_VerificationCase> _applyFilters(List<_VerificationCase> cases) {
    Iterable<_VerificationCase> records = cases.where((record) {
      switch (_activeTab) {
        case 0:
          return record.status == 'Under Review' ||
              record.status == 'In Review' ||
              record.status == 'Changes Requested';
        case 1:
          return record.verificationStage == 'Awaiting Final Approval';
        case 2:
          return record.status == 'Verified';
        case 3:
          return record.status == 'Rejected';
        default:
          return true;
      }
    });

    if (_urgentOnly) {
      records = records.where((record) => record.isUrgent);
    }
    if (_finalApprovalOnly) {
      records = records.where((record) => record.canFinalApprove);
    }
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      records = records.where(
        (record) =>
            record.family.toLowerCase().contains(query) ||
            record.location.toLowerCase().contains(query),
      );
    }

    final results = records.toList();
    results.sort(
      (a, b) => _newestFirst
          ? b.submittedOrder.compareTo(a.submittedOrder)
          : a.submittedOrder.compareTo(b.submittedOrder),
    );
    return results;
  }

  Widget _buildTabs(List<_VerificationCase> cases) {
    final active = cases
        .where(
          (c) =>
              c.status == 'Under Review' ||
              c.status == 'In Review' ||
              c.status == 'Changes Requested',
        )
        .length;
    final finalApproval = cases
        .where((c) => c.verificationStage == 'Awaiting Final Approval')
        .length;
    final approved = cases.where((c) => c.status == 'Verified').length;
    final rejected = cases.where((c) => c.status == 'Rejected').length;

    final tabs = [
      'Active ($active)',
      'Final Approval ($finalApproval)',
      'Approved ($approved)',
      'Rejected ($rejected)',
    ];

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final activeTab = _activeTab == index;
            return GestureDetector(
              onTap: () => setState(() => _activeTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: activeTab
                          ? NavJeevanColors.primaryRose
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: activeTab
                        ? NavJeevanColors.primaryRose
                        : NavJeevanColors.textSoft,
                    fontWeight: activeTab ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: NavJeevanColors.primaryRose.withValues(alpha: 0.02),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(
              'Urgent',
              _urgentOnly,
              onTap: () => setState(() => _urgentOnly = !_urgentOnly),
            ),
            const SizedBox(width: 8),
            _filterChip(
              'Newest First',
              _newestFirst,
              isBlue: true,
              onTap: () => setState(() => _newestFirst = !_newestFirst),
            ),
            const SizedBox(width: 8),
            _filterChip(
              'Final Approval',
              _finalApprovalOnly,
              onTap: () =>
                  setState(() => _finalApprovalOnly = !_finalApprovalOnly),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndActions(List<_VerificationCase> filtered) {
    return Container(
      color: NavJeevanColors.primaryRose.withValues(alpha: 0.02),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search by family or location',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: NavJeevanColors.pureWhite,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${filtered.length} case(s) visible',
                  style: NavJeevanTextStyles.bodySmall.copyWith(
                    color: NavJeevanColors.textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _urgentOnly = false;
                    _newestFirst = true;
                    _finalApprovalOnly = false;
                    _activeTab = 0;
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

  Widget _filterChip(
    String label,
    bool active, {
    bool isBlue = false,
    required VoidCallback onTap,
  }) {
    Color bg = isBlue ? Colors.blue.shade50 : NavJeevanColors.pureWhite;
    Color text = isBlue ? Colors.blue.shade700 : NavJeevanColors.textDark;
    if (active && !isBlue) {
      bg = NavJeevanColors.petalLight.withValues(alpha: 0.5);
      text = NavJeevanColors.primaryRose;
    }
    if (active && isBlue) {
      bg = Colors.blue.shade50;
      text = Colors.blue.shade700;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: text.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: text,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              active ? Icons.check_circle : Icons.circle_outlined,
              size: 14,
              color: text,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyCard(_VerificationCase record) {
    final statusBg = _statusBg(record.status);
    final statusColor = _statusColor(record.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NavJeevanColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: NavJeevanColors.borderColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: NavJeevanColors.primaryRose.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  Icons.family_restroom_rounded,
                  color: NavJeevanColors.primaryRose,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.family,
                      style: NavJeevanTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Submitted ${record.time}',
                      style: NavJeevanTextStyles.bodySmall.copyWith(
                        color: NavJeevanColors.textSoft,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.verificationStage,
                      style: NavJeevanTextStyles.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  record.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInfoBox('LOCATION', record.location)),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showDocumentsDialog(context, record),
                  child: _buildInfoBox(
                    'DOCUMENTS',
                    record.documentsLabel,
                    icon: Icons.open_in_new,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              record.priority,
              style: NavJeevanTextStyles.bodySmall.copyWith(
                color: record.canFinalApprove
                    ? Colors.green.shade700
                    : NavJeevanColors.textSoft,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDocumentsDialog(context, record),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Review Docs'),
                ),
              ),
              if (record.status == 'Verified' || record.status == 'Child Assigned') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _promptChildAssignment(context, record),
                    icon: const Icon(Icons.child_care_outlined),
                    label: const Text('Assign Child'),
                  ),
                ),
              ],
              if (record.canFinalApprove) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _promptForApplicationDecision(
                      context,
                      record,
                      'Verified',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
              if (record.status != 'Rejected' &&
                  record.status != 'Verified') ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _promptForApplicationDecision(
                    context,
                    record,
                    'Rejected',
                  ),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _promptChildAssignment(
    BuildContext context,
    _VerificationCase record,
  ) async {
    final motherRequestsSnapshot = await FirebaseFirestore.instance
        .collection('mother_requests')
        .where('requestType', isEqualTo: 'child_surrender')
        .get();

    final candidates = motherRequestsSnapshot.docs.where((doc) {
      final data = doc.data();
      final stage = (data['childDocumentStage'] ?? '').toString();
      final assignedParentId = (data['assignedParentId'] ?? '').toString();
      final status = (data['status'] ?? '').toString();
      final blocked = status == 'Declined' || status == 'Cancelled';
      return stage == 'Child Documents Verified' &&
          assignedParentId.isEmpty &&
          !blocked;
    }).toList();

    if (candidates.isEmpty) {
      if (!mounted) return;
      var notVerifiedStageCount = 0;
      var alreadyAssignedCount = 0;
      var blockedStatusCount = 0;

      for (final doc in motherRequestsSnapshot.docs) {
        final data = doc.data();
        final stage = (data['childDocumentStage'] ?? '').toString();
        final assignedParentId = (data['assignedParentId'] ?? '').toString();
        final status = (data['status'] ?? '').toString();

        if (stage != 'Child Documents Verified') {
          notVerifiedStageCount++;
          continue;
        }
        if (assignedParentId.isNotEmpty) {
          alreadyAssignedCount++;
          continue;
        }
        if (status == 'Declined' || status == 'Cancelled') {
          blockedStatusCount++;
        }
      }

      await showDialog<void>(
        context: this.context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('No eligible child available'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No mother surrender request currently satisfies assignment rules.',
                ),
                const SizedBox(height: 10),
                Text('Checked child_surrender requests: ${motherRequestsSnapshot.docs.length}'),
                Text('Not in "Child Documents Verified" stage: $notVerifiedStageCount'),
                Text('Already assigned to a parent: $alreadyAssignedCount'),
                Text('Declined/Cancelled status: $blockedStatusCount'),
                const SizedBox(height: 10),
                const Text(
                  'Required for eligibility:\n'
                  '• childDocumentStage = Child Documents Verified\n'
                  '• assignedParentId must be empty\n'
                  '• status must not be Declined/Cancelled',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (!mounted) {
      return;
    }

    String? selectedRequestId;
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: this.context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Assign child to ${record.family}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedRequestId,
                    decoration: const InputDecoration(
                      labelText: 'Verified child request',
                    ),
                    items: candidates.map((doc) {
                      final data = doc.data();
                      final childProfile = Map<String, dynamic>.from(
                        data['childProfile'] as Map<String, dynamic>? ??
                            <String, dynamic>{},
                      );
                      final childName =
                          (childProfile['name'] ?? 'Child').toString();
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text('$childName • ${doc.id}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedRequestId = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Optional assignment note',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedRequestId == null
                      ? null
                      : () => Navigator.pop(dialogContext, true),
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || selectedRequestId == null) {
      return;
    }

    await FirebaseService.instance.assignChildToVerifiedParent(
      familyId: record.id,
      motherRequestId: selectedRequestId!,
      notes: notesController.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(content: Text('Child assigned to ${record.family} successfully.')),
    );
  }

  Future<void> _showDocumentsDialog(
    BuildContext context,
    _VerificationCase record,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final entries = record.documents.entries.toList();
        return AlertDialog(
          title: Text('${record.family} documents'),
          content: SizedBox(
            width: double.maxFinite,
            child: entries.isEmpty
                ? const Text('No documents uploaded.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: entries.length,
                      separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final document = Map<String, dynamic>.from(
                        entry.value as Map<String, dynamic>? ??
                            <String, dynamic>{},
                      );
                      final type = (document['type'] ?? entry.key).toString();
                      final status =
                          (document['verificationStatus'] ?? 'Pending')
                              .toString();
                      final notes = (document['verificationNotes'] ?? '')
                          .toString();
                      final url = (document['downloadUrl'] ?? '').toString();
                        final storageProvider =
                          (document['storageProvider'] ?? 'unknown').toString();
                        final cloudinaryPublicId =
                          (document['storagePath'] ?? '').toString();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            document['fileName']?.toString() ?? 'Unnamed file',
                            style: TextStyle(color: NavJeevanColors.textSoft),
                          ),
                          if (storageProvider.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Storage: $storageProvider${cloudinaryPublicId.isEmpty ? '' : ' • Asset: $cloudinaryPublicId'}',
                              style: TextStyle(
                                color: NavJeevanColors.textSoft,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _statusChip(status),
                              if (notes.isNotEmpty)
                                Text(
                                  'Note: $notes',
                                  style: TextStyle(
                                    color: NavJeevanColors.textSoft,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: url.isEmpty
                                    ? null
                                    : () => _openDocument(url),
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Open'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _promptForDocumentDecision(
                                  dialogContext,
                                  record.id,
                                  entry.key,
                                  type,
                                  'Verified',
                                ),
                                icon: const Icon(Icons.check),
                                label: const Text('Verify'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _promptForDocumentDecision(
                                  dialogContext,
                                  record.id,
                                  entry.key,
                                  type,
                                  'Rejected',
                                ),
                                icon: const Icon(Icons.edit_note),
                                label: const Text('Request update'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _promptForDocumentDecision(
    BuildContext dialogContext,
    String familyId,
    String documentKey,
    String documentType,
    String nextStatus,
  ) async {
    final notesController = TextEditingController();

    await showDialog<void>(
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          title: Text('$nextStatus $documentType'),
          content: TextField(
            controller: notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: nextStatus == 'Rejected'
                  ? 'Explain what should be corrected'
                  : 'Optional admin note',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseService.instance.updateParentDocumentVerification(
                  familyId: familyId,
                  documentKey: documentKey,
                  status: nextStatus,
                  notes: notesController.text.trim(),
                );
                if (!mounted || !context.mounted || !dialogContext.mounted) {
                  return;
                }
                Navigator.pop(context);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('$documentType marked as $nextStatus.'),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _promptForApplicationDecision(
    BuildContext context,
    _VerificationCase record,
    String nextStatus,
  ) async {
    final notesController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('$nextStatus ${record.family}'),
          content: TextField(
            controller: notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: nextStatus == 'Rejected'
                  ? 'Reason for rejection'
                  : 'Optional approval note',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseService.instance.finalizeParentVerification(
                  familyId: record.id,
                  status: nextStatus,
                  notes: notesController.text.trim(),
                );
                if (!mounted || !dialogContext.mounted || !this.context.mounted) {
                  return;
                }
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('${record.family} marked as $nextStatus.'),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusBg(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _statusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Verified':
        return Colors.green.shade50;
      case 'Rejected':
      case 'Changes Requested':
        return Colors.orange.shade50;
      case 'In Review':
      case 'Awaiting Final Approval':
        return Colors.blue.shade50;
      default:
        return Colors.amber.shade50;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Verified':
        return Colors.green.shade800;
      case 'Rejected':
      case 'Changes Requested':
        return Colors.orange.shade800;
      case 'In Review':
      case 'Awaiting Final Approval':
        return Colors.blue.shade800;
      default:
        return Colors.amber.shade800;
    }
  }

  Widget _buildInfoBox(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: NavJeevanColors.primaryRose.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NavJeevanColors.borderColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: NavJeevanColors.textSoft,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: NavJeevanTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (icon != null)
            Icon(icon, size: 20, color: NavJeevanColors.primaryRose),
        ],
      ),
    );
  }
}

class _VerificationCase {
  final String id;
  final String family;
  final String time;
  final String priority;
  final String location;
  final String documentsLabel;
  final String status;
  final String verificationStage;
  final bool isUrgent;
  final bool canFinalApprove;
  final int submittedOrder;
  final Map<String, dynamic> documents;

  const _VerificationCase({
    required this.id,
    required this.family,
    required this.time,
    required this.priority,
    required this.location,
    required this.documentsLabel,
    required this.status,
    required this.verificationStage,
    required this.isUrgent,
    required this.canFinalApprove,
    required this.submittedOrder,
    required this.documents,
  });
}
