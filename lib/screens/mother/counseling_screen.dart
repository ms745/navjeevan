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
import '../../providers/auth_provider.dart';

class CounselingScreen extends StatefulWidget {
  const CounselingScreen({super.key});

  @override
  State<CounselingScreen> createState() => _CounselingScreenState();
}

class _CounselingScreenState extends State<CounselingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedMode = 'All';

  final List<String> _modes = const ['All', 'Video', 'Audio', 'In-Person'];

  final List<Map<String, dynamic>> _counselors = [
    {
      'id': 'counselor_1',
      'name': 'Dr. Sarah Miller',
      'specialty': 'Perinatal Specialist',
      'status': 'Available Now',
      'statusColor': Colors.green,
      'mode': 'Video',
      'languages': 'English, Hindi',
      'experience': '8 years',
      'rating': 4.8,
      'fee': '₹600/session',
      'contact': '+91 9988776611',
      'nextSlot': 'Today, 4:30 PM',
      'about':
          'Focuses on emotional support for pregnancy and early motherhood transitions.',
    },
    {
      'id': 'counselor_2',
      'name': 'Maya Thompson',
      'specialty': 'Family Therapist',
      'status': 'Next in 2 Hours',
      'statusColor': Colors.orange,
      'mode': 'In-Person',
      'languages': 'English, Marathi',
      'experience': '6 years',
      'rating': 4.6,
      'fee': '₹500/session',
      'contact': '+91 9988776622',
      'nextSlot': 'Today, 6:00 PM',
      'about':
          'Helps mothers and families manage conflict, stress, and communication challenges.',
    },
    {
      'id': 'counselor_3',
      'name': 'Dr. James Chen',
      'specialty': 'Child Psychologist',
      'status': 'Available Now',
      'statusColor': Colors.green,
      'mode': 'Audio',
      'languages': 'English',
      'experience': '10 years',
      'rating': 4.9,
      'fee': '₹700/session',
      'contact': '+91 9988776633',
      'nextSlot': 'Today, 5:15 PM',
      'about':
          'Supports mothers on child behavior, bonding, and developmental well-being.',
    },
  ];

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

  Future<void> _callCounselor(String contact) async {
    final Uri callUri = Uri(scheme: 'tel', path: contact.replaceAll(' ', ''));
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open dialer right now.')),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int availableNow = _counselors
        .where((c) => (c['status'] as String) == 'Available Now')
        .length;
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
      body: SingleChildScrollView(
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
            // Assigned Counselor Section with Firebase Integration
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
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
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
                      onPressed: () {
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
                      },
                      icon: const Icon(Icons.calendar_month, size: 16),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NavJeevanColors.primaryRose,
                        foregroundColor: Colors.white,
                      ),
                      label: const Text('Book Session'),
                    ),
                  ),
                ],
              ),
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
                        onPressed: () {
                          context.push(
                            NavJeevanRoutes.motherCounselingBooking,
                            extra: counselor,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NavJeevanColors.primaryRose,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('View & Book'),
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
                  _callCounselor('+91 8047121098');
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
                onTap: () {
                  Navigator.pop(context);
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
                onTap: () {
                  Navigator.pop(context);
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
