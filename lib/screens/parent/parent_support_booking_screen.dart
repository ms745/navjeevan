import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_names.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/parent_colors.dart';
import '../../core/widgets/error_popup.dart';

class ParentSupportBookingScreen extends StatefulWidget {
  const ParentSupportBookingScreen({
    super.key,
    required this.serviceType,
    required this.accentColor,
    required this.counselor,
  });

  final String serviceType;
  final Color accentColor;
  final Map<String, dynamic> counselor;

  @override
  State<ParentSupportBookingScreen> createState() =>
      _ParentSupportBookingScreenState();
}

class _ParentSupportBookingScreenState
    extends State<ParentSupportBookingScreen> {
  DateTime? _selectedDate;
  String _selectedMode = 'Video';
  String? _selectedSlot;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _modes = const ['Video', 'Audio', 'In-Person'];
  final List<String> _slots = const [
    '09:30 AM',
    '11:00 AM',
    '02:30 PM',
    '04:00 PM',
    '06:30 PM',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _confirmBooking() async {
    if (_selectedDate == null || _selectedSlot == null) {
      showErrorBottomPopup(context, 'Please select date and time slot first.');
      return;
    }
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final counselor = widget.counselor;
      final counselorId =
          (counselor['id'] ?? counselor['email'] ?? counselor['name'] ?? 'unknown')
              .toString();
      final counselorName = (counselor['name'] ?? 'Counselor').toString();
      final counselorEmail = (counselor['email'] ?? '').toString();
      final notes = _notesController.text.trim();

      await FirebaseService.instance.createParentSupportCounselingBooking(
        serviceType: widget.serviceType,
        counselorId: counselorId,
        counselorName: counselorName,
        counselorEmail: counselorEmail,
        sessionMode: _selectedMode,
        sessionDate: _selectedDate!,
        slot: _selectedSlot!,
        notes: notes.isEmpty
            ? 'Parent support booking for ${widget.serviceType}'
            : notes,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$counselorName booked for ${widget.serviceType}.'),
          backgroundColor: ParentThemeColors.successGreen,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      showErrorBottomPopup(context, 'Booking failed: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final counselor = widget.counselor;
    final name = (counselor['name'] ?? 'Counselor').toString();
    final specialty =
        (counselor['specialty'] ?? widget.serviceType).toString();
    final rating = (counselor['rating'] ?? 4.5).toString();
    final experience =
        (counselor['experience'] ?? '5 years').toString();
    final fee = (counselor['fee'] ?? '₹500/session').toString();
    final about = (counselor['about'] ??
            'Support specialist available for guided sessions.')
        .toString();

    return Scaffold(
      backgroundColor: ParentThemeColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: ParentThemeColors.pureWhite,
        foregroundColor: ParentThemeColors.textDark,
        elevation: 0,
        title: const Text('Book Counselor Session'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ParentThemeColors.pureWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ParentThemeColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ParentThemeColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specialty,
                    style: const TextStyle(
                      fontSize: 13,
                      color: ParentThemeColors.textMid,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '⭐ $rating • $experience • $fee',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ParentThemeColors.textMid,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    about,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ParentThemeColors.textMid,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Session Mode',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ParentThemeColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _modes.map((mode) {
                final selected = mode == _selectedMode;
                return ChoiceChip(
                  label: Text(mode),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedMode = mode),
                  selectedColor: widget.accentColor.withValues(alpha: 0.18),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Date',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ParentThemeColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                _selectedDate == null
                    ? 'Choose Date'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Available Time Slots',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ParentThemeColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _slots.map((slot) {
                final selected = slot == _selectedSlot;
                return ChoiceChip(
                  label: Text(slot),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedSlot = slot),
                  selectedColor: widget.accentColor.withValues(alpha: 0.18),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Additional Notes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ParentThemeColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Mention your concern, preferred language, urgency, or any family context...',
                filled: true,
                fillColor: ParentThemeColors.pureWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                ),
                child: Text(_isSubmitting ? 'Booking...' : 'Confirm Session'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
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
