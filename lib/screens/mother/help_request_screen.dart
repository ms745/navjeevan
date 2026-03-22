import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/constants/route_names.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/error_popup.dart';

class HelpRequestScreen extends StatefulWidget {
  const HelpRequestScreen({super.key});

  @override
  State<HelpRequestScreen> createState() => _HelpRequestScreenState();
}

class _HelpRequestScreenState extends State<HelpRequestScreen> {
  static const List<String> _requiredChildDocuments = [
    'Birth / Age Proof',
    'Medical Record',
    'Immunization Record',
    'Guardian ID / Declaration',
    'Surrender Consent Document',
  ];

  bool _isAnonymous = true;
  bool _isLoading = false;
  bool _isPickingPhoto = false;
  int _currentStep = 0;
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _otherReasonController = TextEditingController();
  final TextEditingController _otherRegionController = TextEditingController();
  final TextEditingController _childAgeController = TextEditingController();
  final TextEditingController _childWeightController = TextEditingController();
  final TextEditingController _childHeightController = TextEditingController();
  final TextEditingController _childComplexionController = TextEditingController();
  final TextEditingController _childSpecialFeaturesController = TextEditingController();
  final TextEditingController _childMedicalNotesController = TextEditingController();
  final TextEditingController _childBloodGroupController = TextEditingController();
  final TextEditingController _childNicknameController = TextEditingController();
  final List<String> _reasons = [
    'Financial Difficulty',
    'Social Pressure',
    'Domestic Violence',
    'Health Support',
    'Legal Aid',
    'Education Support',
    'Other',
  ];
  final List<String> _regions = const [
    'Kothrud',
    'Viman Nagar',
    'Hinjewadi',
    'Baner',
    'Hadapsar',
    'Pimpri Chinchwad',
    'Camp',
    'Other',
  ];
  String? _selectedReason = 'Financial Difficulty';
  String? _selectedRegion;
  String _selectedChildGender = 'Unknown';
  String _selectedHealthStatus = 'Stable';
  double _urgencyLevel = 2;
  String _preferredContact = 'Phone';
  Uint8List? _childPhotoBytes;
  String? _childPhotoName;
  final Map<String, Uint8List> _childDocumentBytes = <String, Uint8List>{};
  final Map<String, String> _childDocumentNames = <String, String>{};

  int get _totalSteps => 3;

  bool get _isOtherReasonSelected => _selectedReason == 'Other';
  bool get _isOtherRegionSelected => _selectedRegion == 'Other';

  String? get _effectiveSelectedReason {
    if (_isOtherReasonSelected) {
      return _otherReasonController.text.trim().isEmpty
          ? null
          : _otherReasonController.text.trim();
    }
    return _selectedReason;
  }

  String? get _effectiveSelectedRegion {
    if (_isOtherRegionSelected) {
      return _otherRegionController.text.trim().isEmpty
          ? null
          : _otherRegionController.text.trim();
    }
    return _selectedRegion;
  }

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
    _otherReasonController.dispose();
    _otherRegionController.dispose();
    _childAgeController.dispose();
    _childWeightController.dispose();
    _childHeightController.dispose();
    _childComplexionController.dispose();
    _childSpecialFeaturesController.dispose();
    _childMedicalNotesController.dispose();
    _childBloodGroupController.dispose();
    _childNicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickChildPhoto() async {
    setState(() => _isPickingPhoto = true);
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _childPhotoBytes = bytes;
        _childPhotoName = image.name;
      });
    } catch (error) {
      if (mounted) {
        showErrorBottomPopup(context, 'Unable to pick child photo: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  Future<void> _pickChildDocument(String docType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) {
        return;
      }

      final file = result.files.single;
      setState(() {
        _childDocumentBytes[docType] = file.bytes!;
        _childDocumentNames[docType] = file.name;
      });
    } catch (error) {
      if (mounted) {
        showErrorBottomPopup(context, 'Unable to pick child document: $error');
      }
    }
  }

  String? _validateCurrentStep() {
    if (_currentStep == 0) {
      final reasonError = NavJeevanValidator.validateReasons(
        _effectiveSelectedReason != null ? [_effectiveSelectedReason!] : [],
      );
      final regionError = NavJeevanValidator.validateRegion(
        _effectiveSelectedRegion,
      );
      return reasonError ?? regionError;
    }

    if (_currentStep == 1) {
      if (_childAgeController.text.trim().isEmpty ||
          _childWeightController.text.trim().isEmpty ||
          _childHeightController.text.trim().isEmpty ||
          _childComplexionController.text.trim().isEmpty) {
        return 'Please provide child age, weight, height, and complexion details.';
      }
      if (_childPhotoBytes == null) {
        return 'Please upload at least one child photo.';
      }
      final missingDocs = _requiredChildDocuments
          .where((doc) => !_childDocumentBytes.containsKey(doc))
          .toList();
      if (missingDocs.isNotEmpty) {
        return 'Upload all required child documents before continuing.';
      }
    }

    return null;
  }

  void _nextStep() {
    final error = _validateCurrentStep();
    if (error != null) {
      showErrorBottomPopup(context, error);
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _callEmergencyHelpline() async {
    final Uri uri = Uri(scheme: 'tel', path: '1098');
    await FirebaseService.instance.logEmergencyCall(
      helpline: '1098',
      source: 'mother_help_request_sos',
      outcome: 'Dial requested',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _submitRequest() async {
    final validationError = _validateCurrentStep();
    if (validationError != null) {
      showErrorBottomPopup(context, validationError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final requestId = await FirebaseService.instance.submitMotherRequest(
        reasons: _effectiveSelectedReason != null ? [_effectiveSelectedReason!] : [],
        needsCounseling: true,
        isAnonymous: _isAnonymous,
        region: _effectiveSelectedRegion!,
        additionalDetails: _detailsController.text.trim(),
        urgencyLevel: _urgencyLevel,
        preferredContact: _preferredContact,
        childPhotoBytes: _childPhotoBytes,
        childPhotoFileName: _childPhotoName,
        childDocumentBytes: _childDocumentBytes,
        childDocumentFileNames: _childDocumentNames,
        childProfile: {
          'nickname': _childNicknameController.text.trim(),
          'age': _childAgeController.text.trim(),
          'gender': _selectedChildGender,
          'complexion': _childComplexionController.text.trim(),
          'weightKg': _childWeightController.text.trim(),
          'heightCm': _childHeightController.text.trim(),
          'healthStatus': _selectedHealthStatus,
          'bloodGroup': _childBloodGroupController.text.trim(),
          'specialFeatures': _childSpecialFeaturesController.text.trim(),
          'medicalNotes': _childMedicalNotesController.text.trim(),
        },
      );

      if (!mounted) return;

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
                    color: NavJeevanColors.blush.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What happens next:',
                        style: NavJeevanTextStyles.titleLarge.copyWith(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• A verified counselor will review your request',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• You\'ll receive a call/message within 24 hours',
                      ),
                      const SizedBox(height: 8),
                      Text('• Preferred mode: $_preferredContact'),
                      const SizedBox(height: 8),
                      Text('• Estimated first response: $_estimatedResponse'),
                      const SizedBox(height: 8),
                      Text(
                        '• Child summary: ${_childAgeController.text.trim()} • $_selectedChildGender • ${_childWeightController.text.trim()} kg',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Request ID: $requestId',
                        style: NavJeevanTextStyles.bodySmall.copyWith(
                          color: NavJeevanColors.primaryRose,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_isAnonymous)
                  const Text(
                    '🔒 Your request is anonymous and your identity is protected.',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.go(NavJeevanRoutes.motherHelpRequest);
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      );
    } catch (e) {
      final message = e.toString();
      if (message.contains('already have an active surrender request')) {
        showErrorBottomPopup(context, message.replaceFirst('Bad state: ', ''));
      } else {
        showErrorBottomPopup(context, 'Submission failed: $message');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            tooltip: 'My Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(NavJeevanRoutes.motherProfile),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSosButton(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildStepProgress(),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildCurrentStepContent(),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildStepActions(),
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

  Widget _buildStepProgress() {
    final titles = ['Support Details', 'Child & Documents', 'Review & Submit'];
    return Row(
      children: List.generate(_totalSteps, (index) {
        final active = index == _currentStep;
        final complete = index < _currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == _totalSteps - 1 ? 0 : 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active || complete
                  ? NavJeevanColors.blush
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active || complete
                    ? NavJeevanColors.primaryRose
                    : NavJeevanColors.borderColor,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: complete
                      ? NavJeevanColors.successGreen
                      : active
                      ? NavJeevanColors.primaryRose
                      : NavJeevanColors.backgroundLight,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  titles[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? NavJeevanColors.primaryRose
                        : NavJeevanColors.textSoft,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildSupportDetailsStep();
      case 1:
        return _buildChildAndDocsStep();
      default:
        return _buildReviewSubmitStep();
    }
  }

  Widget _buildSupportDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnonymousCard(),
        const SizedBox(height: 24),
        _buildReasonSection(),
        const SizedBox(height: 24),
        _buildRegionSection(),
      ],
    );
  }

  Widget _buildChildAndDocsStep() {
    return Column(
      children: [
        _buildChildDetailsSection(),
        const SizedBox(height: 24),
        _buildChildDocumentsSection(),
      ],
    );
  }

  Widget _buildReviewSubmitStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAdditionalDetailsSection(),
        const SizedBox(height: 24),
        _buildUrgencySection(),
        const SizedBox(height: 16),
        _buildPreferredContactSection(),
        const SizedBox(height: 24),
        _buildRequestSummaryCard(),
      ],
    );
  }

  Widget _buildStepActions() {
    final isFinalStep = _currentStep == _totalSteps - 1;
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              child: const Text('Back'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : isFinalStep
                ? _submitRequest
                : _nextStep,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isFinalStep ? 'Submit Request' : 'Continue'),
          ),
        ),
      ],
    );
  }

  Widget _buildAnonymousCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NavJeevanColors.borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: NavJeevanColors.primaryRose),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anonymous Mode',
                  style: NavJeevanTextStyles.titleLarge.copyWith(fontSize: 16),
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
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite_rounded, color: NavJeevanColors.primaryRose, size: 20),
            const SizedBox(width: 8),
            Text('Reason for seeking help', style: NavJeevanTextStyles.titleLarge.copyWith(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _reasons.map((reason) => ChoiceChip(
            label: Text(reason),
            selected: _selectedReason == reason,
            onSelected: (selected) {
              setState(() {
                _selectedReason = selected ? reason : null;
                if (_selectedReason != 'Other') {
                  _otherReasonController.clear();
                }
              });
            },
            selectedColor: NavJeevanColors.blush,
            backgroundColor: Colors.white,
          )).toList(),
        ),
        if (_isOtherReasonSelected) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _otherReasonController,
            decoration: const InputDecoration(hintText: 'Enter your specific reason'),
          ),
        ],
      ],
    );
  }

  Widget _buildRegionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Neighborhood (Pune)',
          style: NavJeevanTextStyles.labelLarge.copyWith(color: NavJeevanColors.textDark),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedRegion,
          decoration: const InputDecoration(hintText: 'Select Region'),
          items: _regions.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
          onChanged: (val) {
            setState(() {
              _selectedRegion = val;
              if (_selectedRegion != 'Other') {
                _otherRegionController.clear();
              }
            });
          },
        ),
        if (_isOtherRegionSelected) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _otherRegionController,
            decoration: const InputDecoration(hintText: 'Enter your current region'),
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Additional Details (Optional)', style: NavJeevanTextStyles.labelLarge.copyWith(color: NavJeevanColors.textDark)),
        const SizedBox(height: 8),
        TextField(
          controller: _detailsController,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Tell us how we can help you specifically...'),
        ),
      ],
    );
  }

  Widget _buildUrgencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Urgency Level', style: NavJeevanTextStyles.labelLarge.copyWith(color: NavJeevanColors.textDark)),
        Slider(
          value: _urgencyLevel,
          min: 1,
          max: 5,
          divisions: 4,
          activeColor: NavJeevanColors.primaryRose,
          label: _urgencyLevel.toStringAsFixed(0),
          onChanged: (value) => setState(() => _urgencyLevel = value),
        ),
        Text('Estimated response: $_estimatedResponse', style: NavJeevanTextStyles.bodySmall.copyWith(color: NavJeevanColors.primaryRose, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPreferredContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preferred Contact Mode', style: NavJeevanTextStyles.labelLarge.copyWith(color: NavJeevanColors.textDark)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['Phone', 'WhatsApp', 'In-App Chat'].map((mode) => ChoiceChip(
            label: Text(mode),
            selected: _preferredContact == mode,
            onSelected: (_) => setState(() => _preferredContact = mode),
            selectedColor: NavJeevanColors.blush,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildChildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.folder_open_rounded, color: NavJeevanColors.primaryRose, size: 20),
            const SizedBox(width: 8),
            Text('Child Documents', style: NavJeevanTextStyles.titleLarge.copyWith(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
        ..._requiredChildDocuments.map((docType) => _buildChildDocumentCard(docType)).toList(),
      ],
    );
  }

  Widget _buildChildDocumentCard(String docType) {
    final fileName = _childDocumentNames[docType];
    final uploaded = fileName != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: uploaded ? NavJeevanColors.successGreen.withValues(alpha: 0.35) : NavJeevanColors.borderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(uploaded ? Icons.check_circle : Icons.upload_file, color: uploaded ? NavJeevanColors.successGreen : NavJeevanColors.primaryRose),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(docType, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(fileName ?? 'Accepted: PDF, DOC, DOCX, JPG, JPEG, PNG', style: NavJeevanTextStyles.bodySmall),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _pickChildDocument(docType),
            child: Text(uploaded ? 'Replace' : 'Upload'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestSummaryCard() {
    return Container(
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
          Text('Review Summary', style: NavJeevanTextStyles.titleLarge.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          _summaryRow('Reason', _effectiveSelectedReason ?? '-'),
          _summaryRow('Region', _effectiveSelectedRegion ?? '-'),
          _summaryRow('Child Age', _childAgeController.text.trim()),
          _summaryRow('Child Gender', _selectedChildGender),
          _summaryRow('Health Status', _selectedHealthStatus),
          _summaryRow('Child Documents', '${_childDocumentNames.length}/${_requiredChildDocuments.length} uploaded'),
          _summaryRow('Preferred Contact', _preferredContact),
          _summaryRow('Urgency', _urgencyLevel.toStringAsFixed(0)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: NavJeevanTextStyles.bodySmall)),
          Expanded(child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _buildChildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.child_care_rounded,
              color: NavJeevanColors.primaryRose,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Child Details for Surrender',
              style: NavJeevanTextStyles.titleLarge.copyWith(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _childNicknameController,
          hintText: 'Child nickname / temporary name (optional)',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _childAgeController,
                hintText: 'Age (e.g. 8 months)',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedChildGender,
                decoration: const InputDecoration(hintText: 'Child gender'),
                items: const [
                  DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Intersex', child: Text('Intersex')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedChildGender = value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _childWeightController,
                hintText: 'Weight in kg',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _childHeightController,
                hintText: 'Height in cm',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _childComplexionController,
                hintText: 'Complexion / skin tone',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _childBloodGroupController,
                hintText: 'Blood group (optional)',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedHealthStatus,
          decoration: const InputDecoration(hintText: 'Current health status'),
          items: const [
            DropdownMenuItem(value: 'Stable', child: Text('Stable')),
            DropdownMenuItem(value: 'Needs Observation', child: Text('Needs Observation')),
            DropdownMenuItem(value: 'Requires Medical Attention', child: Text('Requires Medical Attention')),
            DropdownMenuItem(value: 'Special Care', child: Text('Special Care')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedHealthStatus = value);
            }
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _childSpecialFeaturesController,
          hintText: 'Special features / identification marks',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _childMedicalNotesController,
          hintText: 'Medical notes, allergies, disability, medications',
          maxLines: 3,
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NavJeevanColors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Child Photo',
                style: NavJeevanTextStyles.titleLarge.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (_childPhotoBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _childPhotoBytes!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: NavJeevanColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Upload a clear child photo'),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                _childPhotoName ?? 'No photo selected',
                style: NavJeevanTextStyles.bodySmall.copyWith(
                  color: NavJeevanColors.textSoft,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _isPickingPhoto ? null : _pickChildPhoto,
                  icon: _isPickingPhoto
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _childPhotoBytes == null
                              ? Icons.add_a_photo_outlined
                              : Icons.refresh,
                        ),
                  label: Text(
                    _childPhotoBytes == null ? 'Select Photo' : 'Replace Photo',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(hintText: hintText),
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
            color: Colors.red.withValues(alpha: 0.3),
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
                        color: Colors.white.withValues(alpha: 0.9),
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
