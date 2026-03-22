import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/route_names.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/parent_colors.dart';
import '../../core/widgets/error_popup.dart';

class ParentVerificationStatusScreen extends StatefulWidget {
  const ParentVerificationStatusScreen({super.key});

  @override
  State<ParentVerificationStatusScreen> createState() =>
      _ParentVerificationStatusScreenState();
}

class _ParentVerificationStatusScreenState
    extends State<ParentVerificationStatusScreen> {
  Future<void> _refreshStatus() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _reuploadDocument(String docType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      await FirebaseService.instance.reuploadParentDocument(
        docType: docType,
        filePath: result.files.single.path!,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$docType uploaded again for verification.'),
          backgroundColor: ParentThemeColors.successGreen,
        ),
      );
    } catch (error) {
      if (mounted) {
        showErrorBottomPopup(context, 'Unable to upload document: $error');
      }
    }
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted) {
        showErrorBottomPopup(context, 'Invalid document link.');
      }
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      showErrorBottomPopup(context, 'Unable to open the document.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentThemeColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseService.instance
                    .watchCurrentParentApplication(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final documentSnapshot = snapshot.data;
                  final data = documentSnapshot?.data();
                  if (documentSnapshot == null ||
                      !documentSnapshot.exists ||
                      data == null ||
                      data.isEmpty) {
                    return _buildEmptyState();
                  }

                  final summary = Map<String, dynamic>.from(
                    data['verificationSummary'] as Map<String, dynamic>? ??
                        <String, dynamic>{},
                  );
                  final documents = Map<String, dynamic>.from(
                    data['documents'] as Map<String, dynamic>? ??
                        <String, dynamic>{},
                  );

                  return RefreshIndicator(
                    onRefresh: _refreshStatus,
                    color: ParentThemeColors.primaryBlue,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTrustBanner(),
                          const SizedBox(height: 16),
                          _buildProgressOverview(data, summary),
                          const SizedBox(height: 16),
                          _buildDocumentStatusList(documents),
                          const SizedBox(height: 16),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseService.instance
                                .watchParentApplicationEvents(
                                  documentSnapshot.id,
                                ),
                            builder: (context, eventSnapshot) {
                              final events = eventSnapshot.data?.docs ?? [];
                              return _buildActivityTimeline(events);
                            },
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(color: ParentThemeColors.skyBlue, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: ParentThemeColors.textDark,
            ),
            onPressed: () => context.pop(),
          ),
          const Text(
            'Application Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ParentThemeColors.textDark,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: ParentThemeColors.textDark,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ParentThemeColors.pureWhite,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 72,
                color: ParentThemeColors.primaryBlue,
              ),
              const SizedBox(height: 16),
              const Text(
                'No parent application found',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ParentThemeColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete the adoption registration first. After submitting documents, every verification stage will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ParentThemeColors.textMid,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () =>
                    context.go(NavJeevanRoutes.parentRegistrationWizard),
                icon: const Icon(Icons.app_registration),
                label: const Text('Start Registration'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ParentThemeColors.primaryBlue,
                  foregroundColor: ParentThemeColors.pureWhite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ParentThemeColors.skyBlue.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ParentThemeColors.primaryBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ParentThemeColors.primaryBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.verified_user,
              color: ParentThemeColors.pureWhite,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your submitted files are stored securely. Admin verification updates appear here in real time.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ParentThemeColors.textMid,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview(
    Map<String, dynamic> data,
    Map<String, dynamic> summary,
  ) {
    final totalDocuments = (summary['totalDocuments'] ?? 0) as int;
    final verifiedCount = (summary['verifiedCount'] ?? 0) as int;
    final rejectedCount = (summary['rejectedCount'] ?? 0) as int;
    final pendingCount = (summary['pendingCount'] ?? 0) as int;
    final percentComplete = (summary['percentComplete'] ?? 0) as int;
    final stage = (data['verificationStage'] ?? 'Awaiting Uploads').toString();
    final status = (data['adoptionStatus'] ?? 'Draft').toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ParentThemeColors.skyBlue.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['familyName']?.toString() ?? 'Parent application',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ParentThemeColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stage,
            style: TextStyle(
              color: _statusColor(status),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentComplete / 100,
              minHeight: 12,
              backgroundColor: ParentThemeColors.skyBlue,
              valueColor: AlwaysStoppedAnimation<Color>(_statusColor(status)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$verifiedCount of $totalDocuments documents verified',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: ParentThemeColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildSummaryPill(
                'Verified',
                '$verifiedCount',
                ParentThemeColors.successGreen,
              ),
              _buildSummaryPill(
                'Pending',
                '$pendingCount',
                ParentThemeColors.warningOrange,
              ),
              _buildSummaryPill(
                'Rejected',
                '$rejectedCount',
                ParentThemeColors.primaryBlue,
              ),
              _buildSummaryPill(
                'Progress',
                '$percentComplete%',
                _statusColor(status),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentStatusList(Map<String, dynamic> documents) {
    if (documents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Document verification stages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ParentThemeColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ...documents.entries.map((entry) {
            final document = Map<String, dynamic>.from(
              entry.value as Map<String, dynamic>? ?? <String, dynamic>{},
            );
            final docType = (document['type'] ?? entry.key).toString();
            final status = (document['verificationStatus'] ?? 'Pending')
                .toString();
            final fileName = (document['fileName'] ?? 'Unnamed file')
                .toString();
            final notes = (document['verificationNotes'] ?? '').toString();
            final url = (document['downloadUrl'] ?? '').toString();
            final canReupload = status != 'Verified';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _statusColor(status).withValues(alpha: 0.25),
                ),
                color: _statusColor(status).withValues(alpha: 0.06),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              docType,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: ParentThemeColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fileName,
                              style: TextStyle(
                                color: ParentThemeColors.textMid,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _statusColor(status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Admin note: $notes',
                      style: TextStyle(
                        color: ParentThemeColors.textMid,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (url.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => _openDocument(url),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open file'),
                        ),
                      if (canReupload)
                        ElevatedButton.icon(
                          onPressed: () => _reuploadDocument(docType),
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            status == 'Rejected'
                                ? 'Upload updated file'
                                : 'Re-upload',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ParentThemeColors.primaryBlue,
                            foregroundColor: ParentThemeColors.pureWhite,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> events,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ParentThemeColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Text(
              'Verification events will appear here.',
              style: TextStyle(color: ParentThemeColors.textMid),
            )
          else
            ...events.take(6).map((eventDoc) {
              final event = eventDoc.data();
              final title = (event['title'] ?? 'Status updated').toString();
              final description =
                  (event['description'] ?? 'No details provided').toString();
              final status = (event['status'] ?? '').toString();
              final createdAt = event['createdAt'] as Timestamp?;
              final timeLabel = createdAt == null
                  ? 'just now'
                  : '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _statusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ParentThemeColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: TextStyle(color: ParentThemeColors.textMid),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeLabel,
                            style: TextStyle(
                              color: ParentThemeColors.textSoft,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.textMid.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context: context,
            icon: Icons.dashboard_outlined,
            label: 'Status',
            isActive: true,
            onTap: () {},
          ),
          _buildNavItem(
            context: context,
            icon: Icons.menu_book,
            label: 'Guidance',
            isActive: false,
            onTap: () => context.push(NavJeevanRoutes.parentGuidance),
          ),
          _buildNavItem(
            context: context,
            icon: Icons.support_agent,
            label: 'Support',
            isActive: false,
            onTap: () => context.push(NavJeevanRoutes.parentSupport),
          ),
          _buildNavItem(
            context: context,
            icon: Icons.person_outline,
            label: 'Profile',
            isActive: false,
            onTap: () => context.push(NavJeevanRoutes.parentProfile),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? ParentThemeColors.primaryBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? ParentThemeColors.primaryBlue
                  : ParentThemeColors.textMid,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? ParentThemeColors.primaryBlue
                    : ParentThemeColors.textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'verification completed':
        return ParentThemeColors.successGreen;
      case 'rejected':
      case 'changes requested':
        return ParentThemeColors.primaryBlue;
      case 'in review':
      case 'document review in progress':
      case 'awaiting final approval':
        return ParentThemeColors.warningOrange;
      default:
        return ParentThemeColors.primaryBlue;
    }
  }
}
