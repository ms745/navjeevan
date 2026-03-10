import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/services/firebase_service.dart';
import 'package:intl/intl.dart';

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
  bool _homeStudyOnly = false;

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
          final createdAt = data['createdAt'] as Timestamp?;
          final status = data['adoptionStatus'] ?? 'Pending';
          
          return _VerificationCase(
            id: doc.id,
            family: data['familyName'] ?? 'Unknown Family',
            time: createdAt != null 
                ? DateFormat('MMM d, HH:mm').format(createdAt.toDate())
                : 'Recently',
            priority: data['annualIncome'] != null && 
                     double.tryParse(data['annualIncome'].toString()) != null &&
                     double.parse(data['annualIncome'].toString()) > 1000000 
                     ? 'High Priority' : 'Standard',
            location: data['region'] ?? 'Unknown Location',
            documents: status == 'Verified' ? 'All Verified' : 'Documents Uploaded',
            status: status,
            imageUrl: '', 
            isUrgent: status == 'Pending',
            submittedOrder: createdAt?.millisecondsSinceEpoch ?? 0,
            canFinalApprove: status == 'In Review',
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
                          color: NavJeevanColors.borderColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'No families found for the selected tab/filters.',
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
          return record.status == 'Pending';
        case 1:
          return record.status == 'In Review';
        case 2:
          return record.status == 'Verified' || record.status == 'Approved';
        case 3:
          return record.status == 'Rejected';
        default:
          return true;
      }
    });

    if (_urgentOnly) {
      records = records.where((record) => record.isUrgent);
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
    final pending = cases.where((c) => c.status == 'Pending').length;
    final inReview = cases.where((c) => c.status == 'In Review').length;
    final approved = cases.where((c) => c.status == 'Verified' || c.status == 'Approved').length;
    final rejected = cases.where((c) => c.status == 'Rejected').length;
    
    final tabs = [
      'Pending ($pending)',
      'In Review ($inReview)',
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
            final active = _activeTab == index;
            return GestureDetector(
              onTap: () => setState(() => _activeTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? NavJeevanColors.primaryRose : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: active ? NavJeevanColors.primaryRose : NavJeevanColors.textSoft,
                    fontWeight: active ? FontWeight.bold : FontWeight.w500,
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
              onTap: () {
                setState(() => _urgentOnly = !_urgentOnly);
              },
            ),
            const SizedBox(width: 8),
            _filterChip(
              'Newest First',
              _newestFirst,
              isBlue: true,
              onTap: () {
                setState(() => _newestFirst = !_newestFirst);
              },
            ),
            const SizedBox(width: 8),
            _filterChip(
              'Home Study',
              _homeStudyOnly,
              onTap: () {
                setState(() => _homeStudyOnly = !_homeStudyOnly);
              },
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
                    _homeStudyOnly = false;
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 56,
                  height: 56,
                  color: NavJeevanColors.primaryRose.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.family_restroom_rounded,
                    color: NavJeevanColors.primaryRose,
                  ),
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
                    Row(
                      children: [
                        Text(
                          'Submitted ${record.time} • ',
                          style: NavJeevanTextStyles.bodySmall.copyWith(
                            color: NavJeevanColors.textSoft,
                          ),
                        ),
                        Text(
                          record.priority,
                          style: NavJeevanTextStyles.bodySmall.copyWith(
                            color: record.isUrgent
                                ? NavJeevanColors.primaryRose
                                : NavJeevanColors.textSoft,
                            fontWeight: record.isUrgent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
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
                    fontSize: 9,
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
              Expanded(child: _buildInfoBox('DOCUMENTS', record.documents)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (record.canFinalApprove) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseService.instance.updateVerificationStatus(record.id, 'Verified');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NavJeevanColors.primaryRose,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'FINAL APPROVAL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await FirebaseService.instance.updateVerificationStatus(record.id, 'Rejected');
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: NavJeevanColors.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'REJECT',
                      style: TextStyle(
                        color: NavJeevanColors.textSoft,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ] else if (record.status == 'Pending') ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseService.instance.updateVerificationStatus(record.id, 'In Review');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade700,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'MARK AS IN-REVIEW',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: NavJeevanColors.primaryRose.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.visibility_rounded,
                      color: NavJeevanColors.primaryRose,
                    ),
                    onPressed: () {
                      // Logic to view detail
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Verified':
      case 'Approved':
        return Colors.green.shade50;
      case 'Rejected':
        return Colors.red.shade50;
      case 'In Review':
        return Colors.blue.shade50;
      default:
        return Colors.amber.shade50;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Verified':
      case 'Approved':
        return Colors.green.shade800;
      case 'Rejected':
        return Colors.red.shade700;
      case 'In Review':
        return Colors.blue.shade800;
      default:
        return Colors.amber.shade800;
    }
  }

  Widget _buildInfoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: NavJeevanColors.primaryRose.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NavJeevanColors.borderColor.withValues(alpha: 0.2),
        ),
      ),
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
    );
  }
}

class _VerificationCase {
  final String id;
  final String family;
  final String time;
  final String priority;
  final String location;
  String documents;
  String status;
  final String imageUrl;
  final bool isUrgent;
  bool canFinalApprove;
  final int submittedOrder;

  _VerificationCase({
    required this.id,
    required this.family,
    required this.time,
    required this.priority,
    required this.location,
    required this.documents,
    required this.status,
    required this.imageUrl,
    required this.submittedOrder,
    this.isUrgent = false,
    this.canFinalApprove = false,
  });
}
