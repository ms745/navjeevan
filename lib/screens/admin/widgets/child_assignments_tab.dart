import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/services/firebase_service.dart';

class ChildAssignmentsTab extends StatefulWidget {
  const ChildAssignmentsTab({super.key});

  @override
  State<ChildAssignmentsTab> createState() => _ChildAssignmentsTabState();
}

class _ChildAssignmentsTabState extends State<ChildAssignmentsTab> {
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.instance.watchAssignedChildRequests(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load assignments',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snap.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        // Filter: only those with a non-empty assignedParentId
        // and sort by assignedAt descending (client-side)
        final allDocs = (snap.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['assignedParentId'] ?? '').toString().isNotEmpty;
        }).toList()
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTs = aData['assignedAt'];
            final bTs = bData['assignedAt'];
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return (bTs as Timestamp)
                .compareTo(aTs as Timestamp);
          });

        // Apply search
        final query = _searchQuery.trim().toLowerCase();
        final docs = query.isEmpty
            ? allDocs
            : allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final childProfile =
                    data['childProfile'] as Map<String, dynamic>? ?? {};
                final nickname =
                    (childProfile['nickname'] ?? '').toString().toLowerCase();
                final parentName =
                    (data['assignedParentFamilyName'] ?? '')
                        .toString()
                        .toLowerCase();
                final region =
                    (data['region'] ?? '').toString().toLowerCase();
                return nickname.contains(query) ||
                    parentName.contains(query) ||
                    region.contains(query);
              }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(allDocs.length),
            _buildSearchBar(),
            Expanded(
              child: docs.isEmpty
                  ? _buildEmptyState(allDocs.isEmpty)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: docs.length,
                      itemBuilder: (context, index) =>
                          _buildAssignmentCard(docs[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      color: NavJeevanColors.pureWhite,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: NavJeevanColors.successGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.family_restroom_rounded,
              color: NavJeevanColors.successGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Child–Parent Assignments',
                  style: NavJeevanTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: NavJeevanColors.textDark,
                  ),
                ),
                Text(
                  '$count ${count == 1 ? 'child' : 'children'} successfully placed',
                  style: NavJeevanTextStyles.bodySmall.copyWith(
                    color: NavJeevanColors.successGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: NavJeevanColors.pureWhite,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search by child name, parent, or region…',
          hintStyle: TextStyle(
            color: NavJeevanColors.textSoft,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: NavJeevanColors.textSoft,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: NavJeevanColors.backgroundLight,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool noAssignmentsAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              noAssignmentsAtAll
                  ? Icons.family_restroom_outlined
                  : Icons.search_off_rounded,
              size: 64,
              color: NavJeevanColors.textSoft.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              noAssignmentsAtAll
                  ? 'No assignments yet'
                  : 'No results match your search',
              style: NavJeevanTextStyles.titleSmall.copyWith(
                color: NavJeevanColors.textSoft,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              noAssignmentsAtAll
                  ? 'Once a verified child is assigned to a verified parent,\nthe placement will appear here.'
                  : 'Try a different name, parent or region.',
              textAlign: TextAlign.center,
              style: NavJeevanTextStyles.bodySmall.copyWith(
                color: NavJeevanColors.textSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final childProfile = data['childProfile'] as Map<String, dynamic>? ?? {};
    final childPhotoMap = data['childPhoto'] as Map<String, dynamic>? ?? {};

    final nickname = (childProfile['nickname'] ?? '').toString();
    final age = (childProfile['age'] ?? '').toString();
    final gender = (childProfile['gender'] ?? '').toString();
    final healthStatus = (childProfile['healthStatus'] ?? '').toString();
    final specialFeatures = (childProfile['specialFeatures'] ?? '').toString();
    final childPhotoUrl = (childPhotoMap['downloadUrl'] ?? '').toString();

    final parentFamilyName =
        (data['assignedParentFamilyName'] ?? 'Unknown Parent').toString();
    final region = (data['region'] ?? '–').toString();
    final requestId = (data['requestId'] ?? doc.id).toString();

    Timestamp? assignedAt;
    final rawAssignedAt = data['assignedAt'];
    if (rawAssignedAt is Timestamp) assignedAt = rawAssignedAt;

    final assignedDateStr = assignedAt != null
        ? _formatDate(assignedAt.toDate())
        : '–';

    final genderColor = gender.toLowerCase() == 'female'
        ? NavJeevanColors.primaryRose
        : const Color(0xFF4A90D9);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: NavJeevanColors.successGreen.withValues(alpha: 0.25),
        ),
      ),
      elevation: 0,
      color: NavJeevanColors.pureWhite,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetailSheet(context, data, doc.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: NavJeevanColors.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            NavJeevanColors.successGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 12,
                          color: NavJeevanColors.successGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Assigned',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: NavJeevanColors.successGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    assignedDateStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: NavJeevanColors.textSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Main row: child photo + child info + arrow + parent info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Child avatar
                  _buildChildAvatar(childPhotoUrl, gender, genderColor),
                  const SizedBox(width: 12),

                  // Child details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nickname.isNotEmpty ? nickname : 'Unnamed Child',
                          style: NavJeevanTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: NavJeevanColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _infoRow(
                          Icons.cake_outlined,
                          'Age: $age',
                          genderColor,
                        ),
                        _infoRow(
                          gender.toLowerCase() == 'female'
                              ? Icons.female_rounded
                              : Icons.male_rounded,
                          gender.isNotEmpty ? gender : '–',
                          genderColor,
                        ),
                        if (healthStatus.isNotEmpty)
                          _infoRow(
                            Icons.health_and_safety_outlined,
                            healthStatus,
                            Colors.orange,
                          ),
                        if (specialFeatures.isNotEmpty)
                          _infoRow(
                            Icons.star_outline_rounded,
                            specialFeatures,
                            NavJeevanColors.textSoft,
                          ),
                      ],
                    ),
                  ),

                  // Arrow connector
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: NavJeevanColors.successGreen
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: NavJeevanColors.successGreen,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 8),

                  // Parent details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assigned Family',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9C6A7A),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: NavJeevanColors.primaryRose
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.home_rounded,
                                size: 16,
                                color: NavJeevanColors.primaryRose,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                parentFamilyName,
                                style: NavJeevanTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: NavJeevanColors.textDark,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _infoRow(
                          Icons.location_on_outlined,
                          region,
                          NavJeevanColors.textSoft,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: NavJeevanColors.borderColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),

              // Footer: request ID
              Row(
                children: [
                  Icon(
                    Icons.tag_rounded,
                    size: 12,
                    color: NavJeevanColors.textSoft,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Request: $requestId',
                      style: TextStyle(
                        fontSize: 11,
                        color: NavJeevanColors.textSoft,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showDetailSheet(context, data, doc.id),
                    child: Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 11,
                        color: NavJeevanColors.primaryRose,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildChildAvatar(
      String photoUrl, String gender, Color genderColor) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: genderColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(gender, genderColor),
              )
            : _avatarFallback(gender, genderColor),
      ),
    );
  }

  Widget _avatarFallback(String gender, Color genderColor) {
    return Container(
      color: genderColor.withValues(alpha: 0.08),
      child: Icon(
        gender.toLowerCase() == 'female'
            ? Icons.face_retouching_natural_rounded
            : Icons.face_rounded,
        size: 32,
        color: genderColor.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: NavJeevanColors.textSoft,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet(
      BuildContext context, Map<String, dynamic> data, String docId) {
    final childProfile = data['childProfile'] as Map<String, dynamic>? ?? {};
    final childPhotoMap = data['childPhoto'] as Map<String, dynamic>? ?? {};

    final nickname = (childProfile['nickname'] ?? '').toString();
    final age = (childProfile['age'] ?? '–').toString();
    final gender = (childProfile['gender'] ?? '–').toString();
    final healthStatus = (childProfile['healthStatus'] ?? '–').toString();
    final bloodGroup = (childProfile['bloodGroup'] ?? '–').toString();
    final heightCm = (childProfile['heightCm'] ?? '–').toString();
    final weightKg = (childProfile['weightKg'] ?? '–').toString();
    final medicalNotes = (childProfile['medicalNotes'] ?? '').toString();
    final specialFeatures = (childProfile['specialFeatures'] ?? '').toString();
    final childPhotoUrl = (childPhotoMap['downloadUrl'] ?? '').toString();

    final parentFamilyName =
        (data['assignedParentFamilyName'] ?? 'Unknown Parent').toString();
    final assignedParentId = (data['assignedParentId'] ?? '').toString();
    final region = (data['region'] ?? '–').toString();
    final requestId = (data['requestId'] ?? docId).toString();
    final riskLevel = (data['riskLevel'] ?? '–').toString();

    Timestamp? assignedAt;
    final rawAssignedAt = data['assignedAt'];
    if (rawAssignedAt is Timestamp) assignedAt = rawAssignedAt;
    final assignedDateStr =
        assignedAt != null ? _formatDateFull(assignedAt.toDate()) : '–';

    final genderColor = gender.toLowerCase() == 'female'
        ? NavJeevanColors.primaryRose
        : const Color(0xFF4A90D9);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      children: [
                        // Header
                        Row(
                          children: [
                            _buildChildAvatar(
                                childPhotoUrl, gender, genderColor),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nickname.isNotEmpty
                                        ? nickname
                                        : 'Unnamed Child',
                                    style:
                                        NavJeevanTextStyles.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: NavJeevanColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: NavJeevanColors.successGreen
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Assigned • $assignedDateStr',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: NavJeevanColors.successGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section: Child Profile
                        _sectionTitle('Child Profile'),
                        _detailGrid([
                          ('Age', age),
                          ('Gender', gender),
                          ('Health', healthStatus),
                          ('Blood Group', bloodGroup.toUpperCase()),
                          ('Height', heightCm.isNotEmpty ? '$heightCm cm' : '–'),
                          ('Weight', weightKg.isNotEmpty ? '$weightKg kg' : '–'),
                        ]),
                        if (specialFeatures.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _noteCard(
                              'Special Features', specialFeatures, Icons.star_rounded),
                        ],
                        if (medicalNotes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _noteCard('Medical Notes', medicalNotes,
                              Icons.medical_information_outlined),
                        ],
                        const SizedBox(height: 16),

                        // Section: Assignment
                        _sectionTitle('Assignment Details'),
                        _assignmentConnector(
                            region, parentFamilyName, assignedDateStr),
                        const SizedBox(height: 16),

                        // Section: Reference
                        _sectionTitle('Reference'),
                        _detailGrid([
                          ('Request ID', requestId),
                          ('Parent ID', assignedParentId),
                          ('Region', region),
                          ('Risk Level', riskLevel),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: NavJeevanColors.textSoft,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _detailGrid(List<(String, String)> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: NavJeevanColors.backgroundLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: NavJeevanColors.borderColor.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.$1,
                style: TextStyle(
                  fontSize: 10,
                  color: NavJeevanColors.textSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.$2.isNotEmpty ? item.$2 : '–',
                style: TextStyle(
                  fontSize: 13,
                  color: NavJeevanColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _noteCard(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NavJeevanColors.backgroundLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: NavJeevanColors.borderColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: NavJeevanColors.textSoft),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: NavJeevanColors.textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: NavJeevanColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignmentConnector(
      String region, String parentName, String dateStr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            NavJeevanColors.primaryRose.withValues(alpha: 0.05),
            NavJeevanColors.successGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NavJeevanColors.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Icon(Icons.child_care_rounded,
                    color: NavJeevanColors.primaryRose, size: 28),
                const SizedBox(height: 4),
                Text(
                  'Child',
                  style: TextStyle(
                    fontSize: 12,
                    color: NavJeevanColors.primaryRose,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  region,
                  style: TextStyle(
                    fontSize: 11,
                    color: NavJeevanColors.textSoft,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Column(
            children: [
              Icon(Icons.arrow_forward_rounded,
                  color: NavJeevanColors.successGreen, size: 24),
              const SizedBox(height: 2),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 10,
                  color: NavJeevanColors.successGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                Icon(Icons.home_rounded,
                    color: const Color(0xFF4A90D9), size: 28),
                const SizedBox(height: 4),
                Text(
                  'Parent',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF4A90D9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  parentName,
                  style: TextStyle(
                    fontSize: 11,
                    color: NavJeevanColors.textSoft,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatDateFull(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
