import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/error_popup.dart';

class CounselingBookingScreen extends StatefulWidget {
  final Map<String, dynamic>? counselor;

  const CounselingBookingScreen({super.key, this.counselor});

  @override
  State<CounselingBookingScreen> createState() =>
      _CounselingBookingScreenState();
}

class _CounselingBookingScreenState extends State<CounselingBookingScreen> {
  DateTime? _selectedDate;
  String _selectedMode = 'Video';
  String? _selectedSlot;
  final TextEditingController _notesController = TextEditingController();

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
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
    });
  }

  void _confirmBooking() {
    if (_selectedDate == null || _selectedSlot == null) {
      showErrorBottomPopup(context, 'Please select date and time slot first.');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session booked successfully.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> counselor =
        widget.counselor ??
        {
          'name': 'Counselor',
          'specialty': 'Support Specialist',
          'rating': 4.5,
          'experience': '5 years',
          'fee': '₹500/session',
          'about': 'Counseling support for mothers.',
        };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Counseling Session'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NavJeevanColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    counselor['name'] as String,
                    style: NavJeevanTextStyles.titleLarge.copyWith(
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    counselor['specialty'] as String,
                    style: NavJeevanTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '⭐ ${counselor['rating']} • ${counselor['experience']} • ${counselor['fee']}',
                    style: NavJeevanTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    counselor['about'] as String,
                    style: NavJeevanTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Session Mode', style: NavJeevanTextStyles.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _modes.map((mode) {
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
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('Select Date', style: NavJeevanTextStyles.titleLarge),
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
            Text('Available Time Slots', style: NavJeevanTextStyles.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _slots.map((slot) {
                final bool selected = slot == _selectedSlot;
                return ChoiceChip(
                  label: Text(slot),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedSlot = slot;
                    });
                  },
                  selectedColor: NavJeevanColors.blush,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('Additional Notes', style: NavJeevanTextStyles.titleLarge),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Mention your concern, preferred language, or urgency...',
                filled: true,
                fillColor: NavJeevanColors.petalLight,
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
                onPressed: _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NavJeevanColors.primaryRose,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Confirm Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
