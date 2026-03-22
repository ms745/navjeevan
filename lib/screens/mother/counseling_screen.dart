import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/constants/route_names.dart';
import '../../core/services/firebase_service.dart';
import '../../core/constants/dummy_agency_data.dart';
import '../../core/widgets/error_popup.dart';
import '../../providers/auth_provider.dart';

class CounselingScreen extends StatefulWidget {
  const CounselingScreen({super.key});

  @override
  State<CounselingScreen> createState() => _CounselingScreenState();
}

class _CounselingScreenState extends State<CounselingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _screenTabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedMode = 'All';
  String _selectedHistoryFilter = 'All';

  final List<String> _modes = const ['All', 'Video', 'Audio', 'In-Person'];

  String _modeFromSpecialty(String specialty) {
    final value = specialty.toLowerCase();
    if (value.contains('legal') || value.contains('law')) return 'In-Person';
    if (value.contains('medical') || value.contains('maternal') || value.contains('health')) {
      return 'Audio';
    }
    return 'Video';
  }

  late final List<Map<String, dynamic>> _counselors =
      DummyAgencyData.agencyCounsellors.map((c) {
        final isAvailable = c.status == 'available';
        final mode = _modeFromSpecialty(c.specialty);
        return {
          'id': c.email ?? c.name,
          'name': c.name,
          'specialty': c.specialty,
          'status': isAvailable ? 'Available Now' : 'Next in 2 Hours',
          'statusColor': isAvailable ? Colors.green : Colors.orange,
          'mode': mode,
          'languages': (c.languages ?? const ['English']).join(', '),
          'experience': '${c.yearsExperience ?? 5} years',
          'rating': c.rating ?? 4.5,
          'fee': mode == 'In-Person' ? '₹700/session' : '₹600/session',
          'contact': c.phone ?? '+91 00000 00000',
          'nextSlot': '${(c.availabilityDays.isNotEmpty ? c.availabilityDays.first : 'Mon')}, 4:30 PM',
          'about': c.bio ?? 'Professional counseling support.',
        };
      }).toList();

  List<Map<String, dynamic>> get _filteredCounselors {
    final String query = _searchController.text.trim().toLowerCase();
    return _counselors.where((counselor) {
      final bool matchesMode =
          _selectedMode == 'All' || counselor['mode'] == _selectedMode;
      final bool matchesQuery =
          query.isEmpty ||
          (counselor['name'] as String).toLowerCase().contains(query) ||
          (counselor['specialty'] as String).toLowerCase().contains(query);
      return matchesMode && matchesQuery;
    }).toList();
  }

  Future<void> _callCounselor(String contact, {bool emergency = false}) async {
    final Uri callUri = Uri(scheme: 'tel', path: contact.replaceAll(' ', ''));
    try {
      await FirebaseService.instance.logCounselorCall(
        contact: contact,
        source: emergency
            ? 'mother_counseling_emergency_call'
            : 'mother_counseling_call',
        isEmergency: emergency,
      );
    } catch (_) {
      // Logging should not block dialing.
    }
    if (emergency) {
      await FirebaseService.instance.logEmergencyCall(
        helpline: contact,
        source: 'mother_counseling_quick_help',
        outcome: 'Dial requested',
      );
    }
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
      return;
    }
    if (!mounted) return;
    showErrorBottomPopup(context, 'Unable to open dialer right now.');
  }

  @override
  void initState() {
    super.initState();
    _screenTabController = TabController(length: 2, vsync: this);
    FirebaseService.instance.ensureSharedCounselorDirectorySeed();
  }

  @override
  void dispose() {
    _screenTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counseling Support'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(NavJeevanRoutes.motherProfile),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TabBar(
              controller: _screenTabController,
              indicatorColor: NavJeevanColors.primaryRose,
              labelColor: NavJeevanColors.primaryRose,
              unselectedLabelColor: NavJeevanColors.textSoft,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'History'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _screenTabController,
              children: [
                _buildOverviewTab(context),
                _buildMotherCounselingHistoryTab(context),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    final int availableNow = _counselors
        .where((c) => (c['status'] as String) == 'Available Now')
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Available Now',
                  '$availableNow Counselors',
                  NavJeevanColors.successGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Avg Wait',
                  '18 mins',
                  NavJeevanColors.warningOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAssignedCounselorSection(context),
          const SizedBox(height: 20),
          Text(
            'Find More Support',
            style: NavJeevanTextStyles.headlineMedium.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by counselor or specialty',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: NavJeevanColors.petalLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final String mode = _modes[index];
                final bool selected = mode == _selectedMode;
                return ChoiceChip(
                  label: Text(mode),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedMode = mode;
                    });
                  },
                  selectedColor: NavJeevanColors.blush,
                  labelStyle: TextStyle(
                    color: selected
                        ? NavJeevanColors.primaryRose
                        : NavJeevanColors.textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: selected
                        ? NavJeevanColors.primaryRose
                        : NavJeevanColors.borderColor,
                  ),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemCount: _modes.length,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Recommended Counselors',
            style: NavJeevanTextStyles.headlineMedium.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 12),
          if (_filteredCounselors.isEmpty)
            _emptyState()
          else
            ..._filteredCounselors.map(
              (c) => _buildCounselorCard(c, context),
            ),
          const SizedBox(height: 20),
          Text(
            'Upcoming Sessions',
            style: NavJeevanTextStyles.headlineMedium.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 12),
          _buildSessionCard(
            'Dr. Sarah Miller',
            'Video Consultation',
            'Tomorrow, 10:00 AM',
            'Starts in 18h 42m',
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildSessionCard(
            'Maya Thompson',
            'Check-in Session',
            'Friday, Oct 25, 2:30 PM',
            null,
            NavJeevanColors.primaryRose,
          ),
          const SizedBox(height: 16),
          _instantSupportCard(),
        ],
      ),
    );
  }

  Widget _buildMotherCounselingHistoryTab(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) {
      return Center(
        child: Text(
          'Login required to view counseling history.',
          style: NavJeevanTextStyles.bodySmall,
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.instance.watchUserAssignments(userId),
      builder: (context, assignmentSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.instance.watchCurrentUserCounselingBookings(),
          builder: (context, bookingSnapshot) {
            final entries = <Map<String, dynamic>>[];

            final assignmentDocs = assignmentSnapshot.data?.docs ?? [];
            for (final doc in assignmentDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final history = (data['history'] as List<dynamic>? ?? const <dynamic>[])
                  .map((entry) => Map<String, dynamic>.from(entry as Map<String, dynamic>))
                  .toList();
              final counselorName = (data['counselorName'] ?? 'Counselor').toString();
              final status = (data['status'] ?? 'Assigned').toString();
              if (history.isEmpty) {
                entries.add({
                  'title': 'Counselor assigned',
                  'subtitle': counselorName,
                  'status': status,
                  'time': data['assignedAt'],
                });
              } else {
                for (final item in history) {
                  entries.add({
                    'title': item['message'] ?? 'Assignment update',
                    'subtitle': counselorName,
                    'status': item['status'] ?? status,
                    'time': item['createdAt'],
                  });
                }
              }
            }

            final bookingDocs = bookingSnapshot.data?.docs ?? [];
            for (final doc in bookingDocs) {
              final data = doc.data() as Map<String, dynamic>;
              entries.add({
                'title': 'Session booking ${(data['status'] ?? 'Requested').toString()}',
                'subtitle': '${(data['counselorName'] ?? 'Counselor').toString()} • ${(data['slot'] ?? '--').toString()}',
                'status': (data['status'] ?? 'Requested').toString(),
                'time': data['updatedAt'] ?? data['createdAt'],
              });
            }

            entries.sort((a, b) {
              final aTs = a['time'];
              final bTs = b['time'];
              if (aTs is! Timestamp && bTs is! Timestamp) return 0;
              if (aTs is! Timestamp) return 1;
              if (bTs is! Timestamp) return -1;
              return bTs.compareTo(aTs);
            });

            final filteredEntries = _selectedHistoryFilter == 'All'
                ? entries
                : entries
                    .where((entry) =>
                        (entry['status'] ?? '').toString() ==
                        _selectedHistoryFilter)
                    .toList();

            if (entries.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No counseling records yet. Your assignments and bookings will appear here.',
                    style: NavJeevanTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'All',
                        'Accepted',
                        'Scheduled',
                        'In Session',
                        'Completed',
                        'Declined',
                      ].map((filter) {
                        final selected = _selectedHistoryFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                _selectedHistoryFilter = filter;
                              });
                            },
                            selectedColor: NavJeevanColors.blush,
                            backgroundColor: NavJeevanColors.petalLight,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? NavJeevanColors.primaryRose
                                  : NavJeevanColors.textSoft,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredEntries.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'No entries for "$_selectedHistoryFilter".',
                              style: NavJeevanTextStyles.bodySmall,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: filteredEntries.length,
                          itemBuilder: (context, index) {
                            final entry = filteredEntries[index];
                final status = (entry['status'] ?? 'Updated').toString();
                final time = entry['time'];
                final timestampText = time is Timestamp
                    ? _formatHistoryDateTime(time.toDate())
                    : '--';

                Color statusColor = NavJeevanColors.textSoft;
                if (status == 'Accepted') {
                  statusColor = NavJeevanColors.successGreen;
                } else if (status == 'Scheduled') {
                  statusColor = NavJeevanColors.warningOrange;
                } else if (status == 'In Session') {
                  statusColor = NavJeevanColors.warningOrange;
                } else if (status == 'Completed') {
                  statusColor = NavJeevanColors.primaryRose;
                } else if (status == 'Declined') {
                  statusColor = NavJeevanColors.deepRose;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NavJeevanColors.borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (entry['title'] ?? 'Update').toString(),
                              style: NavJeevanTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (entry['subtitle'] ?? '').toString(),
                              style: NavJeevanTextStyles.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$status • $timestampText',
                              style: NavJeevanTextStyles.bodySmall.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatHistoryDateTime(DateTime dt) {
    const months = [
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
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final meridian = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $meridian';
  }

  Widget _statCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NavJeevanColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: NavJeevanTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: NavJeevanTextStyles.titleLarge.copyWith(
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NavJeevanColors.petalLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'No counselors match your current filters. Try another mode or search term.',
        style: NavJeevanTextStyles.bodySmall,
      ),
    );
  }

  Widget _buildAssignedCounselorSection(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.instance.watchUserAssignments(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NavJeevanColors.borderColor),
            ),
            child: Text(
              'Unable to load assigned counselor right now.',
              style: NavJeevanTextStyles.bodySmall,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NavJeevanColors.blush.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NavJeevanColors.borderColor),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_add_alt_1,
                  color: NavJeevanColors.primaryRose,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No counselor assigned yet. Our agency will assign one soon.',
                    style: NavJeevanTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          );
        }

        final assignmentDoc = snapshot.data!.docs.first;
        final assignment = assignmentDoc.data() as Map<String, dynamic>;
        final counselorEmail = assignment['counselorEmail'] as String?;
        final counselorName =
            assignment['counselorName'] as String? ?? 'Assigned Counselor';
        final assignmentStatus =
          (assignment['status'] ?? 'Requested').toString();
        final canBookSession = assignmentStatus == 'Accepted' ||
            assignmentStatus == 'Scheduled' ||
            assignmentStatus == 'In Session' ||
            assignmentStatus == 'Completed';
        final assignedSlot = (assignment['slot'] ?? '').toString();
        final history = (assignment['history'] as List<dynamic>? ?? const <dynamic>[])
          .map((entry) => Map<String, dynamic>.from(entry as Map<String, dynamic>))
          .toList();

        final counselor = DummyAgencyData.agencyCounsellors.firstWhere(
          (item) => item.email == counselorEmail,
          orElse: () => DummyAgencyData.agencyCounsellors.first,
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: NavJeevanColors.primaryRose.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 18,
                    color: NavJeevanColors.primaryRose,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Assigned Counselor',
                    style: NavJeevanTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: NavJeevanColors.primaryRose,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(counselor.image),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          counselorName,
                          style: NavJeevanTextStyles.titleLarge.copyWith(
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          counselor.specialty,
                          style: NavJeevanTextStyles.bodySmall,
                        ),
                        if (counselor.rating != null)
                          Text(
                            '⭐ ${counselor.rating} • ${counselor.yearsExperience ?? 0} years',
                            style: NavJeevanTextStyles.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: NavJeevanColors.primaryRose.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Status: $assignmentStatus',
                      style: NavJeevanTextStyles.bodySmall.copyWith(
                        color: NavJeevanColors.primaryRose,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (assignedSlot.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: NavJeevanColors.petalLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Slot: $assignedSlot',
                        style: NavJeevanTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (history.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Latest update: ${(history.first['message'] ?? 'No update').toString()}',
                  style: NavJeevanTextStyles.bodySmall,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (counselor.phone != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _callCounselor(counselor.phone!),
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text('Call'),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: canBookSession
                          ? () {
                              context.push(
                                NavJeevanRoutes.motherCounselingBooking,
                                extra: {
                                  'id': 'assigned_${counselor.email ?? 'na'}',
                                  'name': counselorName,
                                  'specialty': counselor.specialty,
                                  'status': 'Assigned',
                                  'statusColor': NavJeevanColors.primaryRose,
                                  'mode': 'Video',
                                  'languages': (counselor.languages ?? []).join(', '),
                                  'experience':
                                      '${counselor.yearsExperience ?? 0} years',
                                  'rating': counselor.rating ?? 4.5,
                                  'fee': '₹600/session',
                                  'contact': counselor.phone ?? '',
                                  'nextSlot': 'Today, 5:30 PM',
                                  'about': counselor.bio ?? 'Professional counselor',
                                },
                              );
                            }
                          : null,
                      icon: const Icon(Icons.calendar_month, size: 16),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NavJeevanColors.primaryRose,
                        foregroundColor: Colors.white,
                      ),
                      label: Text(canBookSession
                          ? 'Book Session'
                          : 'Await NGO Acceptance'),
                    ),
                  ),
                ],
              ),
              if (!canBookSession) ...[
                const SizedBox(height: 8),
                Text(
                  'Booking unlocks after NGO accepts this counseling request.',
                  style: NavJeevanTextStyles.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCounselorCard(
    Map<String, dynamic> counselor,
    BuildContext context,
  ) {
    final Color statusColor = counselor['statusColor'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: NavJeevanColors.borderColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: NavJeevanColors.blush,
            child: const Icon(
              Icons.person,
              color: NavJeevanColors.primaryRose,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  counselor['name'] as String,
                  style: NavJeevanTextStyles.titleLarge.copyWith(fontSize: 16),
                ),
                Text(
                  counselor['specialty'] as String,
                  style: NavJeevanTextStyles.bodySmall,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (counselor['status'] as String).toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${counselor['mode']} • ⭐ ${counselor['rating']}',
                      style: NavJeevanTextStyles.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${counselor['experience']} • ${counselor['languages']}',
                  style: NavJeevanTextStyles.bodySmall,
                ),
                Text(
                  'Next Slot: ${counselor['nextSlot']}',
                  style: NavJeevanTextStyles.bodySmall.copyWith(
                    color: NavJeevanColors.primaryRose,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _callCounselor(counselor['contact'] as String),
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseService.instance.submitCounselingSupportRequest(
                            requestKind: 'Counseling Session Request',
                            notes:
                                'Requested counselor: ${(counselor['name'] ?? 'Counselor').toString()}',
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Request sent. Booking will unlock after NGO acceptance.',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NavJeevanColors.primaryRose,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Request Session'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _instantSupportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NavJeevanColors.blush.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.forum_rounded,
              color: NavJeevanColors.primaryRose,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need immediate help?',
                  style: NavJeevanTextStyles.titleLarge.copyWith(fontSize: 16),
                ),
                Text(
                  'Instant connect with emergency counselor desk',
                  style: NavJeevanTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showQuickHelpSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: NavJeevanColors.primaryRose,
              minimumSize: const Size(98, 40),
              elevation: 0,
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showQuickHelpSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Counseling Help',
                style: NavJeevanTextStyles.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose the fastest support option available right now.',
                style: NavJeevanTextStyles.bodySmall,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.call,
                  color: NavJeevanColors.primaryRose,
                ),
                title: const Text('Call Emergency Counselor Desk'),
                subtitle: const Text('Average response: under 2 minutes'),
                onTap: () {
                  Navigator.pop(context);
                  _callCounselor('+91 8047121098', emergency: true);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.headset_mic,
                  color: NavJeevanColors.primaryRose,
                ),
                title: const Text('Start Audio Counseling Now'),
                subtitle: const Text('Queue position is assigned instantly'),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseService.instance.submitCounselingSupportRequest(
                    requestKind: 'Instant Audio Counseling',
                    notes: 'Requested from quick help sheet',
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Audio counseling request sent. Connecting you now...',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.schedule,
                  color: NavJeevanColors.primaryRose,
                ),
                title: const Text('Request Callback in 5 Minutes'),
                subtitle: const Text(
                  'A counselor will call your registered number',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseService.instance.submitCounselingSupportRequest(
                    requestKind: 'Callback in 5 Minutes',
                    notes: 'Requested from quick help sheet',
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Callback scheduled in 5 minutes.'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionCard(
    String name,
    String type,
    String time,
    String? countdown,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: NavJeevanTextStyles.titleLarge.copyWith(
                      fontSize: 18,
                    ),
                  ),
                  Text(type, style: NavJeevanTextStyles.bodySmall),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'CONFIRMED',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 14,
                color: NavJeevanColors.textSoft,
              ),
              const SizedBox(width: 4),
              Text(time, style: NavJeevanTextStyles.bodySmall),
              if (countdown != null) ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.hourglass_bottom,
                  size: 14,
                  color: NavJeevanColors.primaryRose,
                ),
                const SizedBox(width: 4),
                Text(
                  countdown,
                  style: NavJeevanTextStyles.bodySmall.copyWith(
                    color: NavJeevanColors.primaryRose,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          if (countdown != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.withValues(alpha: 0.1),
                      foregroundColor: color,
                      elevation: 0,
                      minimumSize: const Size(0, 40),
                    ),
                    child: const Text('Reschedule'),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.more_horiz,
                    color: NavJeevanColors.textSoft,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: NavJeevanColors.borderColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: NavJeevanColors.primaryRose,
        unselectedItemColor: NavJeevanColors.textSoft,
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(NavJeevanRoutes.motherHelpRequest);
              break;
            case 1:
              context.go(NavJeevanRoutes.motherNgoMap);
              break;
            case 2:
              context.go(NavJeevanRoutes.motherCounseling);
              break;
            case 3:
              context.go(NavJeevanRoutes.legalGuidance);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'NGO Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded),
            label: 'Counseling',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel_rounded),
            label: 'Legal',
          ),
        ],
      ),
    );
  }
}
