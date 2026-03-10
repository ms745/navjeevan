import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/parent_colors.dart';
import '../../core/constants/dummy_parent_data.dart';

class ParentVerificationStatusScreen extends StatefulWidget {
  const ParentVerificationStatusScreen({super.key});

  @override
  State<ParentVerificationStatusScreen> createState() =>
      _ParentVerificationStatusScreenState();
}

class _ParentVerificationStatusScreenState
    extends State<ParentVerificationStatusScreen> {
  final Map<String, bool> _expandedSteps = {
    'Document Verification': false,
    'Background Check': true, // Current step expanded by default
    'Home Study Visit': false,
  };

  // Document upload simulation
  final Map<String, bool> _documentsUploaded = {
    'Government ID': true,
    'Income Proof': true,
    'Medical Certificate': true,
    'Police Verification': false,
  };

  Future<void> _refreshStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status updated successfully!'),
          backgroundColor: ParentThemeColors.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleStep(String title) {
    setState(() {
      _expandedSteps[title] = !(_expandedSteps[title] ?? false);
    });
  }

  void _uploadDocument(String docType) {
    setState(() {
      _documentsUploaded[docType] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$docType uploaded successfully'),
        backgroundColor: ParentThemeColors.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentParent = DummyParentData.getCurrentParent();
    final documents = DummyParentData.sampleDocuments;

    return Scaffold(
      backgroundColor: ParentThemeColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, currentParent),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshStatus,
                color: ParentThemeColors.primaryBlue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTrustBanner(),
                      const SizedBox(height: 16),
                      _buildProgressOverview(),
                      const SizedBox(height: 16),
                      _buildVerificationTimeline(documents),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic parent) {
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
              'Your data is encrypted and secure. We follow strict privacy protocols.',
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

  Widget _buildProgressOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ParentThemeColors.skyBlue.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OVERALL PROGRESS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ParentThemeColors.textMid,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Step 1 of 3',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ParentThemeColors.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ParentThemeColors.skyBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '33% Done',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ParentThemeColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.33,
              backgroundColor: ParentThemeColors.skyBlue,
              valueColor: AlwaysStoppedAnimation<Color>(
                ParentThemeColors.primaryBlue,
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: ParentThemeColors.lightTrustGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.format_quote,
                  color: ParentThemeColors.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"The journey of a thousand miles begins with a single step."',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: ParentThemeColors.textMid,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationTimeline(List<dynamic> documents) {
    return Column(
      children: [
        _buildTimelineStep(
          title: 'Document Verification',
          description:
              'All essential files have been reviewed and approved by our legal team.',
          status: 'Verified',
          statusColor: ParentThemeColors.successGreen,
          date: 'OCT 12',
          isCompleted: true,
          icon: Icons.check_circle,
          documents: ['Government ID', 'Income Proof', 'Medical Certificate'],
        ),
        _buildTimelineStep(
          title: 'Background Check',
          description:
              'Police verification and background screening in progress. Typically takes 7-10 business days.',
          status: 'In Progress',
          statusColor: ParentThemeColors.warningOrange,
          date: 'Ongoing',
          isCompleted: false,
          isCurrent: true,
          icon: Icons.hourglass_empty,
          documents: ['Police Verification'],
        ),
        _buildTimelineStep(
          title: 'Home Study Visit',
          description:
              'A social worker will visit your home to assess the living environment and family readiness.',
          status: 'Scheduled',
          statusColor: ParentThemeColors.infoBlue,
          date: 'MAR 20',
          isCompleted: false,
          icon: Icons.schedule,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String description,
    required String status,
    required Color statusColor,
    required String date,
    required bool isCompleted,
    bool isCurrent = false,
    required IconData icon,
    List<String>? documents,
  }) {
    final isExpanded = _expandedSteps[title] ?? false;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted
                    ? statusColor
                    : (isCurrent
                          ? statusColor.withValues(alpha: 0.2)
                          : ParentThemeColors.skyBlue),
                shape: BoxShape.circle,
                boxShadow: isCompleted || isCurrent
                    ? [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                icon,
                color: isCompleted
                    ? ParentThemeColors.pureWhite
                    : (isCurrent ? statusColor : ParentThemeColors.textSoft),
              ),
            ),
            if (!isCompleted || isCurrent)
              Transform.translate(
                offset: const Offset(0, -4),
                child: Container(
                  width: 4,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? statusColor.withValues(alpha: 0.3)
                        : ParentThemeColors.skyBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: documents != null ? () => _toggleStep(title) : null,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ParentThemeColors.pureWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrent
                        ? statusColor.withValues(alpha: 0.3)
                        : ParentThemeColors.borderColor.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ParentThemeColors.primaryBlue.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: ParentThemeColors.textDark,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Active',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (documents != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: ParentThemeColors.textMid,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: ParentThemeColors.textMid,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          isCompleted ? Icons.verified : Icons.schedule,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• $date',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ParentThemeColors.textMid,
                          ),
                        ),
                      ],
                    ),
                    // Expandable document section
                    if (documents != null && isExpanded) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Documents Required:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: ParentThemeColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...documents.map((doc) => _buildDocumentItem(doc)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentItem(String docName) {
    final isUploaded = _documentsUploaded[docName] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isUploaded ? Icons.check_circle : Icons.upload_file,
            size: 20,
            color: isUploaded
                ? ParentThemeColors.successGreen
                : ParentThemeColors.textSoft,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              docName,
              style: TextStyle(fontSize: 13, color: ParentThemeColors.textMid),
            ),
          ),
          if (!isUploaded)
            TextButton(
              onPressed: () => _uploadDocument(docName),
              child: const Text(
                'Upload',
                style: TextStyle(
                  fontSize: 12,
                  color: ParentThemeColors.primaryBlue,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () => _uploadDocument(docName),
              child: const Text(
                'Re-upload',
                style: TextStyle(
                  fontSize: 12,
                  color: ParentThemeColors.textSoft,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.textDark.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                context.push(NavJeevanRoutes.parentGuidance);
              },
              icon: const Icon(Icons.menu_book),
              label: const Text('Guidance'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: ParentThemeColors.primaryBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                context.push(NavJeevanRoutes.parentSupport);
              },
              icon: const Icon(Icons.support_agent),
              label: const Text('Get Support'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: ParentThemeColors.primaryBlue,
                foregroundColor: ParentThemeColors.pureWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
