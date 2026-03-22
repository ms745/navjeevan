import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/route_names.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/parent_colors.dart';
import 'parent_support_booking_screen.dart';

class ParentSupportServiceScreen extends StatefulWidget {
  const ParentSupportServiceScreen({
    super.key,
    required this.serviceType,
    required this.icon,
    required this.accentColor,
  });

  final String serviceType;
  final IconData icon;
  final Color accentColor;

  @override
  State<ParentSupportServiceScreen> createState() =>
      _ParentSupportServiceScreenState();
}

class _ParentSupportServiceScreenState
    extends State<ParentSupportServiceScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _supportRequestsStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _counselorAssignmentsStream;
  late final Stream<QuerySnapshot> _counselorDirectoryStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _counselingBookingsStream;

  String _preferredMode = 'Call';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _seedCounselorDirectoryForParentSupport();
    _supportRequestsStream = FirebaseService.instance.watchParentSupportRequests();
    _counselorAssignmentsStream =
        FirebaseService.instance.watchParentCounselorAssignments();
    _counselorDirectoryStream =
        FirebaseService.instance.watchCounselorDirectory();
    final uid = FirebaseService.instance.currentUser?.uid ?? '__none__';
    _counselingBookingsStream = FirebaseFirestore.instance
      .collection('counseling_bookings')
      .where('userId', isEqualTo: uid)
      .snapshots();
  }

  void _seedCounselorDirectoryForParentSupport() {
    FirebaseService.instance.ensureSharedCounselorDirectorySeed();
  }

  String _deriveCounselorCategory(String specialty) {
    final value = specialty.toLowerCase();
    if (value.contains('legal') || value.contains('law')) return 'legal';
    if (value.contains('medical') || value.contains('maternal') || value.contains('health')) {
      return 'medical';
    }
    return 'general';
  }

  bool _isCounselorAvailableStatus(String status) {
    final value = status.trim().toLowerCase();
    return value.isEmpty || value == 'available' || value == 'active';
  }

  bool _matchesServiceType(Map<String, dynamic> counselor) {
    final category = (counselor['category'] ?? '').toString().toLowerCase().trim();
    final specialty = (counselor['specialty'] ?? '').toString();
    final resolvedCategory =
        category.isNotEmpty ? category : _deriveCounselorCategory(specialty);
    final serviceType = widget.serviceType.toLowerCase();

    if (serviceType.contains('counsel')) {
      return resolvedCategory == 'general';
    }

    if (serviceType.contains('legal')) {
      return resolvedCategory == 'legal';
    }

    if (serviceType.contains('medical')) {
      return resolvedCategory == 'medical';
    }

    return true;
  }

    String get _bookingSource {
    final slug =
      widget.serviceType.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'parent_support_$slug';
    }

  List<Map<String, dynamic>> _sortedByTimestamp(
    List<Map<String, dynamic>> items,
    String field,
  ) {
    final copy = List<Map<String, dynamic>>.from(items);
    copy.sort((a, b) {
      final aTs = a[field];
      final bTs = b[field];
      if (aTs is! Timestamp && bTs is! Timestamp) return 0;
      if (aTs is! Timestamp) return 1;
      if (bTs is! Timestamp) return -1;
      return bTs.compareTo(aTs);
    });
    return copy;
  }

  List<Map<String, dynamic>> _serviceRequests(List<Map<String, dynamic>> requests) {
    final target = widget.serviceType.trim().toLowerCase();
    return _sortedByTimestamp(
      requests
          .where((request) =>
              (request['serviceType'] ?? '').toString().trim().toLowerCase() ==
              target)
          .toList(),
      'createdAt',
    );
  }

  List<Map<String, dynamic>> _serviceAssignments(
    List<Map<String, dynamic>> assignments,
    List<Map<String, dynamic>> requests,
  ) {
    final requestIds = requests
        .map((request) => (request['requestId'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    return _sortedByTimestamp(
      assignments.where((assignment) {
        final supportRequestId =
            (assignment['supportRequestId'] ?? '').toString();
        final requestId = (assignment['requestId'] ?? '').toString();
        return requestIds.contains(supportRequestId) ||
            requestIds.contains(requestId);
      }).toList(),
      'assignedAt',
    );
  }

  List<Map<String, dynamic>> _serviceBookings(
    List<Map<String, dynamic>> bookings,
  ) {
    return _sortedByTimestamp(
      bookings.where((booking) {
        final source = (booking['source'] ?? '').toString();
        return source == _bookingSource;
      }).toList(),
      'createdAt',
    );
  }

  String _formatTimestamp(dynamic value) {
    if (value is! Timestamp) return '--';
    final dt = value.toDate();
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final meridian = dt.hour >= 12 ? 'PM' : 'AM';
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $meridian';
  }

  Future<Map<String, dynamic>> _ensureSupportRequest(
    List<Map<String, dynamic>> requests, {
    String? notes,
  }) async {
    for (final request in requests) {
      final status = (request['status'] ?? '').toString().toLowerCase();
      if (status != 'completed' && status != 'closed' && status != 'cancelled') {
        return request;
      }
    }

    final requestId = await FirebaseService.instance.createParentSupportRequest(
      serviceType: widget.serviceType,
      notes: notes,
    );
    final snapshot = await FirebaseFirestore.instance
        .collection('parent_support_requests')
        .doc(requestId)
        .get();
    return snapshot.data() ?? <String, dynamic>{'requestId': requestId};
  }

  Future<void> _bookCounselor({
    required Map<String, dynamic> counselor,
    required List<Map<String, dynamic>> requests,
    required String mode,
  }) async {
    final user = FirebaseService.instance.currentUser;
    if (user == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final supportRequest = await _ensureSupportRequest(
        requests,
        notes: 'Preferred mode: $mode',
      );
      final requestId = (supportRequest['requestId'] ?? '').toString();
      if (requestId.isEmpty) {
        throw StateError('Support request could not be created.');
      }

      final counselorName = (counselor['name'] ?? 'Counselor').toString();
      final counselorEmail = (counselor['email'] ?? '').toString();
      final ngoId = (supportRequest['ngoId'] ?? '').toString();
      final ngoName = (supportRequest['ngoName'] ?? 'Assigned NGO').toString();

      await FirebaseService.instance.assignCounselorToRequest(
        counselorName: counselorName,
        counselorEmail: counselorEmail,
        requestId: requestId,
        userId: user.uid,
        requestType: 'parent',
        supportRequestId: requestId,
        ngoId: ngoId,
        ngoName: ngoName,
        assignmentStatus: 'Requested',
        slot: 'Preferred mode: $mode',
      );

      await FirebaseService.instance.updateParentSupportRequestStatus(
        requestId: requestId,
        status: 'Counselor Requested',
        phase: 2,
        actorRole: 'parent',
        actorId: user.uid,
        notes: 'Requested $counselorName via $mode.',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$counselorName requested for ${widget.serviceType}.'),
          backgroundColor: ParentThemeColors.successGreen,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not complete booking: $error'),
          backgroundColor: ParentThemeColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _logContact(String contact, String actionLabel) async {
    if (actionLabel == 'Call' && contact.isNotEmpty) {
      await FirebaseService.instance.logCounselorCall(
        contact: contact,
        source: 'parent_support_service_screen',
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$actionLabel action prepared for $contact.'),
        backgroundColor: ParentThemeColors.primaryBlue,
      ),
    );
  }

  Future<void> _openSessionLink(String meetingLink) async {
    final Uri uri = Uri.parse(meetingLink.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open meeting link.'),
        backgroundColor: ParentThemeColors.errorRed,
      ),
    );
  }

  Future<void> _openBookingScreen(Map<String, dynamic> counselor) async {
    final booked = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ParentSupportBookingScreen(
          serviceType: widget.serviceType,
          accentColor: widget.accentColor,
          counselor: counselor,
        ),
      ),
    );

    if (booked == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking saved for ${widget.serviceType}.'),
          backgroundColor: ParentThemeColors.successGreen,
        ),
      );
    }
  }

  bool _isRequestAcceptedForBooking(List<Map<String, dynamic>> requests) {
    if (requests.isEmpty) return false;
    for (final request in requests) {
      final status = (request['status'] ?? '').toString().toLowerCase();
      if (status == 'accepted' ||
          status == 'scheduled' ||
          status == 'in session' ||
          status == 'completed') {
        return true;
      }
    }
    return false;
  }

  Widget _buildHeaderCard(List<Map<String, dynamic>> requests) {
    final activeRequest = requests.isNotEmpty ? requests.first : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.accentColor, widget.accentColor.withValues(alpha: 0.78)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(widget.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.serviceType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activeRequest == null
                      ? 'Browse counselors, create a booking, and track the full workflow here.'
                      : 'Current status: ${(activeRequest['status'] ?? 'Requested').toString()}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableTab(
    List<Map<String, dynamic>> requests,
    List<Map<String, dynamic>> counselors,
  ) {
    final canBookSession = _isRequestAcceptedForBooking(requests);

    if (counselors.isEmpty) {
      return _buildEmptyState(
        'No ${widget.serviceType.toLowerCase()} counselors available right now.',
        Icons.support_agent,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(requests),
        const SizedBox(height: 16),
        ...counselors.map((counselor) {
          final name = (counselor['name'] ?? 'Counselor').toString();
          final specialty = (counselor['specialty'] ?? widget.serviceType).toString();
          final email = (counselor['email'] ?? 'Not available').toString();
          final ngoName = (counselor['ngoName'] ?? 'NGO Linked').toString();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ParentThemeColors.pureWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ParentThemeColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: widget.accentColor.withValues(alpha: 0.14),
                      child: Text(
                        name.isEmpty ? '?' : name[0].toUpperCase(),
                        style: TextStyle(
                          color: widget.accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ParentThemeColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$specialty • $ngoName',
                            style: const TextStyle(
                              fontSize: 12,
                              color: ParentThemeColors.textMid,
                            ),
                          ),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: ParentThemeColors.textSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canBookSession
                        ? () => _openBookingScreen(counselor)
                        : () => _bookCounselor(
                              counselor: counselor,
                              requests: requests,
                              mode: _preferredMode,
                            ),
                    icon: Icon(
                      canBookSession
                          ? Icons.calendar_month_outlined
                          : Icons.send_outlined,
                      size: 18,
                    ),
                    label: Text(canBookSession ? 'Book Session' : 'Send Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildBookButton('Call', Icons.call_outlined, counselors, requests, counselor),
                    _buildBookButton('Message', Icons.message_outlined, counselors, requests, counselor),
                    _buildBookButton('In-person', Icons.location_on_outlined, counselors, requests, counselor),
                  ],
                ),
                if (!canBookSession) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Booking unlocks after NGO accepts your request.',
                    style: TextStyle(
                      fontSize: 11,
                      color: ParentThemeColors.textMid,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBookButton(
    String mode,
    IconData icon,
    List<Map<String, dynamic>> counselors,
    List<Map<String, dynamic>> requests,
    Map<String, dynamic> counselor,
  ) {
    return ElevatedButton.icon(
      onPressed: _isSubmitting
          ? null
          : () => _bookCounselor(
                counselor: counselor,
                requests: requests,
                mode: mode,
              ),
      icon: Icon(icon, size: 16),
      label: Text(mode),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.accentColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHistoryTab(
    List<Map<String, dynamic>> requests,
    List<Map<String, dynamic>> assignments,
    List<Map<String, dynamic>> bookings,
  ) {
    if (requests.isEmpty && assignments.isEmpty && bookings.isEmpty) {
      return _buildEmptyState(
        'No ${widget.serviceType.toLowerCase()} history yet.',
        Icons.history,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...requests.map((request) {
          final history = (request['history'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => Map<String, dynamic>.from(
                  item as Map<String, dynamic>? ?? <String, dynamic>{}))
              .toList()
            ..sort((a, b) {
              final aTs = a['createdAt'];
              final bTs = b['createdAt'];
              if (aTs is! Timestamp && bTs is! Timestamp) return 0;
              if (aTs is! Timestamp) return 1;
              if (bTs is! Timestamp) return -1;
              return bTs.compareTo(aTs);
            });

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ParentThemeColors.pureWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ParentThemeColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request ${(request['requestId'] ?? '').toString()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ParentThemeColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${(request['status'] ?? 'Requested').toString()}',
                  style: TextStyle(
                    color: widget.accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Created: ${_formatTimestamp(request['createdAt'])}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ParentThemeColors.textMid,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Latest updates',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                if (history.isEmpty)
                  const Text(
                    'No updates yet.',
                    style: TextStyle(
                      fontSize: 12,
                      color: ParentThemeColors.textMid,
                    ),
                  )
                else
                  ...history.take(4).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '• ${(item['message'] ?? 'Update').toString()} (${_formatTimestamp(item['createdAt'])})',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
              ],
            ),
          );
        }),
        ...assignments.map((assignment) {
          final feedback = Map<String, dynamic>.from(
            assignment['feedback'] as Map<String, dynamic>? ?? <String, dynamic>{},
          );
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ParentThemeColors.pureWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ParentThemeColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (assignment['counselorName'] ?? 'Counselor').toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ParentThemeColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Status: ${(assignment['status'] ?? 'Requested').toString()}'),
                Text('Booked: ${_formatTimestamp(assignment['assignedAt'])}'),
                if (feedback.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Feedback: ${feedback['rating'] ?? '-'}★ • ${(feedback['comment'] ?? '').toString()}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          );
        }),
        ...bookings.map((booking) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ParentThemeColors.pureWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ParentThemeColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (booking['counselorName'] ?? 'Counselor').toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ParentThemeColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Booking: ${(booking['status'] ?? 'Requested').toString()}'),
                Text('Mode: ${(booking['sessionMode'] ?? '--').toString()}'),
                Text('Date: ${_formatTimestamp(booking['sessionDate'])}'),
                Text('Slot: ${(booking['slot'] ?? '--').toString()}'),
                Text(
                  'Booked on: ${_formatTimestamp(booking['createdAt'])}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBookingTab(
    List<Map<String, dynamic>> requests,
    List<Map<String, dynamic>> counselors,
    List<Map<String, dynamic>> bookings,
  ) {
    final canBookSession = _isRequestAcceptedForBooking(requests);
    final latestRequest = requests.isNotEmpty ? requests.first : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(requests),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ParentThemeColors.pureWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ParentThemeColors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Booking preferences',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ParentThemeColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['Call', 'Message', 'In-person'].map((mode) {
                  final selected = _preferredMode == mode;
                  return ChoiceChip(
                    label: Text(mode),
                    selected: selected,
                    onSelected: (_) => setState(() => _preferredMode = mode),
                    selectedColor: widget.accentColor.withValues(alpha: 0.16),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                latestRequest == null
                    ? 'Choose a counselor below to open the detailed booking flow.'
                    : 'Active request: ${(latestRequest['requestId'] ?? '').toString()} • ${(latestRequest['status'] ?? 'Requested').toString()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: ParentThemeColors.textMid,
                ),
              ),
              if (bookings.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Booked sessions: ${bookings.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.accentColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Quick booking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ParentThemeColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        if (counselors.isEmpty)
          _buildEmptyState('No counselors available for booking.', Icons.event_busy)
        else
          ...counselors.take(5).map((counselor) {
            final name = (counselor['name'] ?? 'Counselor').toString();
            final specialty = (counselor['specialty'] ?? widget.serviceType).toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ParentThemeColors.pureWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ParentThemeColors.borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          specialty,
                          style: const TextStyle(
                            fontSize: 12,
                            color: ParentThemeColors.textMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: canBookSession ? () => _openBookingScreen(counselor) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(canBookSession ? 'Book Session' : 'Await NGO Acceptance'),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildScheduledTab(
    List<Map<String, dynamic>> assignments,
    List<Map<String, dynamic>> bookings,
  ) {
    if (assignments.isEmpty && bookings.isEmpty) {
      return _buildEmptyState(
        'No booked or scheduled counselors yet for this service.',
        Icons.calendar_month_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...bookings.map((booking) {
          final name = (booking['counselorName'] ?? 'Counselor').toString();
          final mode = (booking['sessionMode'] ?? '--').toString();
          final slot = (booking['slot'] ?? '--').toString();
          final status = (booking['status'] ?? 'Requested').toString();
          final meetingLink = (booking['meetingLink'] ?? '').toString();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ParentThemeColors.pureWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ParentThemeColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ParentThemeColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Booking Status: $status'),
                Text('Session Mode: $mode'),
                Text('Session Date: ${_formatTimestamp(booking['sessionDate'])}'),
                Text('Slot: $slot'),
                if (meetingLink.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _openSessionLink(meetingLink),
                    icon: const Icon(Icons.video_call_outlined),
                    label: const Text('Join Session'),
                  ),
                ],
              ],
            ),
          );
        }),
        ...assignments.map((assignment) {
        final name = (assignment['counselorName'] ?? 'Counselor').toString();
        final email = (assignment['counselorEmail'] ?? '').toString();
        final status = (assignment['status'] ?? 'Requested').toString();
        final slot = (assignment['slot'] ?? 'Schedule to be shared').toString();
        final session = Map<String, dynamic>.from(
          assignment['session'] as Map<String, dynamic>? ?? <String, dynamic>{},
        );
        final sessionMode = (session['mode'] ?? '--').toString();
        final scheduledAt = session['scheduledAt'];
        final startedAt = session['startedAt'];
        final endedAt = session['endedAt'];
        final meetingLink = (session['meetingLink'] ?? '').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ParentThemeColors.pureWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ParentThemeColors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ParentThemeColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text('Status: $status'),
              Text('Mode: $sessionMode'),
              Text('Slot: $slot'),
              if (scheduledAt != null)
                Text('Scheduled At: ${_formatTimestamp(scheduledAt)}'),
              if (startedAt != null)
                Text('Started At: ${_formatTimestamp(startedAt)}'),
              if (endedAt != null)
                Text('Ended At: ${_formatTimestamp(endedAt)}'),
              Text(
                email.isEmpty ? 'Contact: Not available' : 'Contact: $email',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (meetingLink.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => _openSessionLink(meetingLink),
                      icon: const Icon(Icons.video_call_outlined),
                      label: const Text('Join Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: email.isEmpty
                        ? null
                        : () => _logContact(email, 'Call'),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Call'),
                  ),
                  OutlinedButton.icon(
                    onPressed: email.isEmpty
                        ? null
                        : () => _logContact(email, 'Message'),
                    icon: const Icon(Icons.message_outlined),
                    label: const Text('Msg'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _logContact(name, 'In-person'),
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('In-person'),
                  ),
                ],
              ),
            ],
          ),
        );
        }),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 46, color: ParentThemeColors.textSoft),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ParentThemeColors.textMid,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: ParentThemeColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: ParentThemeColors.pureWhite,
          foregroundColor: ParentThemeColors.textDark,
          elevation: 0,
          title: Text(widget.serviceType),
          bottom: TabBar(
            isScrollable: true,
            labelColor: widget.accentColor,
            unselectedLabelColor: ParentThemeColors.textMid,
            indicatorColor: widget.accentColor,
            tabs: const [
              Tab(text: 'Available'),
              Tab(text: 'History'),
              Tab(text: 'Booking'),
              Tab(text: 'Scheduled'),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _supportRequestsStream,
          builder: (context, requestSnapshot) {
            final allRequests = (requestSnapshot.data?.docs ?? [])
                .map((doc) => doc.data())
                .toList();
            final requests = _serviceRequests(allRequests);

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _counselorAssignmentsStream,
              builder: (context, assignmentSnapshot) {
                final allAssignments = (assignmentSnapshot.data?.docs ?? [])
                    .map((doc) => doc.data())
                    .toList();
                final assignments = _serviceAssignments(allAssignments, requests);

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _counselingBookingsStream,
                  builder: (context, bookingSnapshot) {
                    final allBookings = (bookingSnapshot.data?.docs ?? [])
                        .map((doc) => doc.data())
                        .toList();
                    final bookings = _serviceBookings(allBookings);

                    return StreamBuilder<QuerySnapshot>(
                      stream: _counselorDirectoryStream,
                      builder: (context, counselorSnapshot) {
                        final allCounselors = (counselorSnapshot.data?.docs ?? const [])
                            .map((doc) => Map<String, dynamic>.from(
                                doc.data() as Map<String, dynamic>? ??
                                    <String, dynamic>{}))
                            .where((item) =>
                                _isCounselorAvailableStatus(
                                  (item['status'] ?? '').toString(),
                                ))
                            .toList();

                        final matchedCounselors = allCounselors
                            .where(_matchesServiceType)
                            .toList();

                        final counselors = matchedCounselors;

                        return TabBarView(
                          children: [
                            _buildAvailableTab(requests, counselors),
                            _buildHistoryTab(requests, assignments, bookings),
                            _buildBookingTab(requests, counselors, bookings),
                            _buildScheduledTab(assignments, bookings),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
        bottomNavigationBar: _buildBottomNav(context),
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
            isActive: false,
            onTap: () => context.push(NavJeevanRoutes.parentVerificationStatus),
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
            isActive: true,
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
}
