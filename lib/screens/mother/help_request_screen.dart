import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/constants/route_names.dart';

class HelpRequestScreen extends StatefulWidget {
  const HelpRequestScreen({super.key});

  @override
  State<HelpRequestScreen> createState() => _HelpRequestScreenState();
}

class _HelpRequestScreenState extends State<HelpRequestScreen> {
  bool _isAnonymous = true;
  final TextEditingController _detailsController = TextEditingController();
  final List<String> _reasons = [
    'Financial Difficulty',
    'Social Pressure',
    'Domestic Violence',
    'Health Support',
    'Legal Aid',
    'Education Support',
  ];
  String? _selectedReason = 'Financial Difficulty';
  String? _selectedRegion;
  double _urgencyLevel = 2;
  String _preferredContact = 'Phone';

  String get _estimatedResponse {
    if (_urgencyLevel >= 4) {
      return 'Under 30 mins';
    }
    if (_urgencyLevel >= 3) {
      return 'Within 2 hours';
    }
    return 'Within 24 hours';
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _callEmergencyHelpline() async {
    final Uri uri = Uri(scheme: 'tel', path: '1098');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Assistance'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SOS Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSosButton(),
            ),

            // Anonymous Mode Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NavJeevanColors.borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      color: NavJeevanColors.primaryRose,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anonymous Mode',
                            style: NavJeevanTextStyles.titleLarge.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Your identity remains hidden from responders.',
                            style: NavJeevanTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAnonymous,
                      onChanged: (val) => setState(() => _isAnonymous = val),
                      activeThumbColor: NavJeevanColors.primaryRose,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Reasons Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: NavJeevanColors.primaryRose,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Reason for seeking help',
                        style: NavJeevanTextStyles.titleLarge.copyWith(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _reasons
                        .map(
                          (reason) => ChoiceChip(
                            label: Text(reason),
                            selected: _selectedReason == reason,
                            onSelected: (selected) {
                              setState(
                                () =>
                                    _selectedReason = selected ? reason : null,
                              );
                            },
                            selectedColor: NavJeevanColors.blush,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: _selectedReason == reason
                                  ? NavJeevanColors.textDark
                                  : NavJeevanColors.textSoft,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: _selectedReason == reason
                                    ? NavJeevanColors.primaryRose
                                    : NavJeevanColors.borderColor,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Region Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Neighborhood (Pune)',
                    style: NavJeevanTextStyles.labelLarge.copyWith(
                      color: NavJeevanColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      hintText: 'Select Region',
                    ),
                    items:
                        [
                              'Kothrud',
                              'Viman Nagar',
                              'Hinjewadi',
                              'Baner',
                              'Hadapsar',
                              'Pimpri Chinchwad',
                              'Camp',
                            ]
                            .map(
                              (city) => DropdownMenuItem(
                                value: city,
                                child: Text(city),
                              ),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => _selectedRegion = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Details (Optional)',
                    style: NavJeevanTextStyles.labelLarge.copyWith(
                      color: NavJeevanColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _detailsController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Tell us how we can help you specifically...',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Urgency Level',
                    style: NavJeevanTextStyles.labelLarge.copyWith(
                      color: NavJeevanColors.textDark,
                    ),
                  ),
                  Slider(
                    value: _urgencyLevel,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: NavJeevanColors.primaryRose,
                    label: _urgencyLevel.toStringAsFixed(0),
                    onChanged: (value) => setState(() => _urgencyLevel = value),
                  ),
                  Text(
                    'Estimated response: $_estimatedResponse',
                    style: NavJeevanTextStyles.bodySmall.copyWith(
                      color: NavJeevanColors.primaryRose,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferred Contact Mode',
                    style: NavJeevanTextStyles.labelLarge.copyWith(
                      color: NavJeevanColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Phone', 'WhatsApp', 'In-App Chat']
                        .map(
                          (mode) => ChoiceChip(
                            label: Text(mode),
                            selected: _preferredContact == mode,
                            onSelected: (_) =>
                                setState(() => _preferredContact = mode),
                            selectedColor: NavJeevanColors.blush,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Show success dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext dialogContext) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text('Request Submitted Successfully! ✓'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              'Your assistance request has been received.',
                              style: NavJeevanTextStyles.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: NavJeevanColors.blush.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'What happens next:',
                                    style: NavJeevanTextStyles.titleLarge
                                        .copyWith(fontSize: 16),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '• A verified counselor will review your request',
                                    style: NavJeevanTextStyles.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '• You\'ll receive a call/message within 24 hours',
                                    style: NavJeevanTextStyles.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '• Preferred mode: $_preferredContact',
                                    style: NavJeevanTextStyles.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '• Estimated first response: $_estimatedResponse',
                                    style: NavJeevanTextStyles.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '• Reference ID: REF-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}',
                                    style: NavJeevanTextStyles.bodySmall
                                        .copyWith(
                                          color: NavJeevanColors.primaryRose,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_isAnonymous)
                              Text(
                                '🔒 Your request is anonymous and your identity is protected.',
                                style: NavJeevanTextStyles.bodySmall.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Back to Home'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Submit Request'),
              ),
            ),

            const SizedBox(height: 16),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'A verified counselor will reach out to you within 24 hours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: NavJeevanColors.textSoft,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 100), // Bottom Nav Spacer
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildSosButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _callEmergencyHelpline,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  Icons.emergency_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EMERGENCY SOS',
                      style: NavJeevanTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      'Call CHILDLINE 1098',
                      style: NavJeevanTextStyles.titleLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: NavJeevanColors.borderColor.withOpacity(0.5)),
        ),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: NavJeevanColors.primaryRose,
        unselectedItemColor: NavJeevanColors.textSoft,
        currentIndex: 0,
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
