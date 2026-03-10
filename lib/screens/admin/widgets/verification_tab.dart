import 'package:flutter/material.dart';
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
  bool _homeStudyOnly = false;

  final List<_VerificationCase> _cases = [
    _VerificationCase(
      family: 'The Miller Family',
      time: '2 hours ago',
      priority: 'High Priority',
      location: 'Austin, Texas',
      documents: '8/10 Uploaded',
      status: 'Pending',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuD-ixILtUHMinsUQHZNYtE6CpSjeQ6iJLcsrVo_kTLx19rO0SjYX4F1HjGaZIPrSq8v_43B1TaBnrpcH_UsqP0AZ3HdpE_7POzX8DQ1F3Lilh5cGj1kKzdV14C-2zmifXA2jGkPhfgn6XFtdt_-t9vn096a537dF_JFCQv9fUdt6xanzJGg9wZNcsRvsRRKO4uGLY-fecNSyYIxiDr2K4qgkcfT5T5VM0hJAJNUZ44P_opX0blFKCzkYURu-X5HVfuv6t8Y9O04552M',
      isUrgent: true,
      submittedOrder: 1,
    ),
    _VerificationCase(
      family: 'Chen-Williams Family',
      time: 'Yesterday',
      priority: 'Standard',
      location: 'Seattle, WA',
      documents: 'All Verified',
      status: 'In Review',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDUrylJOC9LSsaShEC_IwkrUap6KQseA-mGV6WNHwyLMTANbtkjJVlLNaIj37It3dKEoU0uPlhuC4BQ_elo0YuwcNZoSv8AcMuE42JbW0EQ8Lmz30Q5w47FbE9I4YcuEX9Pwg1pWuHmVOXlqvhK-6Z7GWlykZAmWKs2-7L-vah1687-ZmdW87OgApE5qyduwUeAo2gnMJMMPxf6fLtfZqsCu1oT5FbYae0cc89k7x9fWwPVEd0UGM-I_SoyMOh7diBl7Dcn1i7MgcAh',
      canFinalApprove: true,
      homeStudyReady: true,
      submittedOrder: 2,
    ),
    _VerificationCase(
      family: 'The Garcia Family',
      time: '3 days ago',
      priority: 'Standard',
      location: 'Miami, Florida',
      documents: 'Update Requested',
      status: 'Pending',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBY0db_gr0JEO37efkPcN0pjU62Ipf37c07eNab6egfGj_DaUUR9i7z_abUBTcCy2GhspbFpZcRgd6uHGGoP8ZV6s3szm_qKmg3Y1ZPT3uUQdVmuj5KOSc5b1Fcpzc8_DPO27ZBoaNVejl15GWmZNfSOlb5UgX62AM2pSVcDryG10fuZNp1QHGtOii6z9CbmSMJQeMHCPXcOqHXVMZ2lrhphrgwuvw7DGHzE_E2uWFQ64vbfq4-5EL7ojlj8n6r9s4RGqVW9cvg0WpT',
      submittedOrder: 3,
    ),
  ];

  List<String> get _tabs {
    final pending = _cases.where((c) => c.status == 'Pending').length;
    final inReview = _cases.where((c) => c.status == 'In Review').length;
    final approved = _cases.where((c) => c.status == 'Approved').length;
    final rejected = _cases.where((c) => c.status == 'Rejected').length;
    return [
      'Pending ($pending)',
      'In Review ($inReview)',
      'Approved ($approved)',
      'Rejected ($rejected)',
    ];
  }

  List<_VerificationCase> get _filteredCases {
    Iterable<_VerificationCase> records = _cases.where((record) {
      switch (_activeTab) {
        case 0:
          return record.status == 'Pending';
        case 1:
          return record.status == 'In Review';
        case 2:
          return record.status == 'Approved';
        case 3:
          return record.status == 'Rejected';
        default:
          return true;
      }
    });

    if (_urgentOnly) {
      records = records.where((record) => record.isUrgent);
    }
    if (_homeStudyOnly) {
      records = records.where((record) => record.homeStudyReady);
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
          ? a.submittedOrder.compareTo(b.submittedOrder)
          : b.submittedOrder.compareTo(a.submittedOrder),
    );
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabs(),
        _buildFilterChips(),
        _buildSearchAndActions(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_filteredCases.isEmpty)
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
                ..._filteredCases.map(_buildFamilyCard),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: NavJeevanColors.pureWhite,
        border: Border(
          bottom: BorderSide(
            color: NavJeevanColors.borderColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            bool isActive = _activeTab == index;
            return GestureDetector(
              onTap: () => setState(() => _activeTab = index),
              child: Container(
                margin: const EdgeInsets.only(right: 24),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? NavJeevanColors.primaryRose
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  _tabs[index],
                  style: NavJeevanTextStyles.bodyMedium.copyWith(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? NavJeevanColors.primaryRose
                        : NavJeevanColors.textSoft,
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

  Widget _buildSearchAndActions() {
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
                  '${_filteredCases.length} case(s) visible',
                  style: NavJeevanTextStyles.bodySmall.copyWith(
                    color: NavJeevanColors.textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: _filteredCases.isEmpty
                    ? null
                    : () {
                        setState(() {
                          for (final record in _filteredCases) {
                            record.status = 'Approved';
                            record.canFinalApprove = false;
                            record.documents = 'All Verified';
                          }
                        });
                      },
                child: const Text('Approve Visible'),
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
                child: Image.network(
                  record.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 56,
                    height: 56,
                    color: NavJeevanColors.primaryRose.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.family_restroom_rounded,
                      color: NavJeevanColors.primaryRose,
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
                    onPressed: () {
                      setState(() {
                        record.status = 'Approved';
                        record.canFinalApprove = false;
                      });
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
                    onPressed: () {
                      setState(() {
                        record.status = 'Rejected';
                        record.canFinalApprove = false;
                      });
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
              ] else ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        record.status = 'In Review';
                        record.documents = 'All Verified';
                        record.canFinalApprove = true;
                      });
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
                      'REVIEW DOCUMENTS',
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
                      Icons.more_horiz_rounded,
                      color: NavJeevanColors.primaryRose,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'More actions for ${record.family} will be added soon.',
                          ),
                        ),
                      );
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
  _VerificationCase({
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
    this.homeStudyReady = false,
  });

  final String family;
  final String time;
  final String priority;
  final String location;
  String documents;
  String status;
  final String imageUrl;
  final bool isUrgent;
  bool canFinalApprove;
  final bool homeStudyReady;
  final int submittedOrder;
}
