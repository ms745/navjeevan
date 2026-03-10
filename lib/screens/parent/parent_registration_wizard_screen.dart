import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/dummy_parent_data.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/parent_colors.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/validators.dart';

class ParentRegistrationWizardScreen extends StatefulWidget {
  const ParentRegistrationWizardScreen({super.key});

  @override
  State<ParentRegistrationWizardScreen> createState() =>
      _ParentRegistrationWizardScreenState();
}

class _ParentRegistrationWizardScreenState
    extends State<ParentRegistrationWizardScreen> {
  int _currentStep = 0; // Starting from step 1
  final int _totalSteps = 5;
  bool _isSubmitting = false;

  // Controllers for data collection
  final _fullNameController = TextEditingController(text: 'Sarah Mitchell');
  final _emailController = TextEditingController(
    text: 'sarah.mitchell@example.com',
  );
  final _phoneController = TextEditingController(text: '9876509999');
  final _incomeController = TextEditingController(
    text: '850000',
  ); // Sample income

  // Document upload status
  final Map<String, bool> _documentsUploaded = {
    'Government ID': true,
    'Income Proof': true,
    'Medical Certificate': false,
    'Police Verification': false,
    'Home Ownership': false,
  };

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      context.pop();
    }
  }

  void _nextStep() async {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _submitApplication();
    }
  }

  Future<void> _submitApplication() async {
    setState(() => _isSubmitting = true);

    try {
      // 1. Validate (Simplified for this wizard)
      final incomeError = NavJeevanValidator.validateAnnualIncome(
        _incomeController.text,
      );
      if (incomeError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(incomeError), backgroundColor: Colors.red),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // 2. Submit to Firebase (In real app, we'd upload actual files from _documentPaths)
      await FirebaseService.instance.submitAdoptionApplication(
        familyName: _fullNameController.text,
        region: 'Pune', // Derived or selected
        annualIncome: double.tryParse(_incomeController.text) ?? 100000,
        documentPaths: {}, // Empty for now as we use mock paths
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration Submitted Successfully!'),
          backgroundColor: ParentThemeColors.successGreen,
        ),
      );
      context.push(NavJeevanRoutes.parentVerificationStatus);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _uploadDocument(String docType) {
    setState(() {
      _documentsUploaded[docType] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$docType uploaded successfully'),
        backgroundColor: ParentThemeColors.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  double get _progressPercentage => ((_currentStep + 1) / _totalSteps) * 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentThemeColors.offWhite,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProgressCard(),
                    const SizedBox(height: 16),
                    _buildStepContent(),
                  ],
                ),
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(color: ParentThemeColors.skyBlue, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: ParentThemeColors.accentPink.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: ParentThemeColors.deepBlue,
              ),
              onPressed: _previousStep,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'NavJeevan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ParentThemeColors.textDark,
            ),
          ),
          const Spacer(),
          Builder(
            builder: (context) {
              final parent = DummyParentData.getCurrentParent();
              final initials = parent.familyName.isNotEmpty
                  ? parent.familyName[0].toUpperCase()
                  : 'P';
              return Row(
                children: [
                  CircleAvatar(
                    backgroundColor: ParentThemeColors.primaryBlue,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: ParentThemeColors.pureWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    parent.familyName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ParentThemeColors.textMid,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ParentThemeColors.skyBlue.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                    _getStepTitle(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: ParentThemeColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Step ${_currentStep + 1} of $_totalSteps: ${_getStepSubtitle()}',
                    style: TextStyle(
                      fontSize: 13,
                      color: ParentThemeColors.textMid,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: ParentThemeColors.adoptionWarmthGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: ParentThemeColors.pinkDark.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${_progressPercentage.toInt()}% Done',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: ParentThemeColors.pureWhite,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progressPercentage / 100,
              backgroundColor: ParentThemeColors.skyBlue,
              valueColor: const AlwaysStoppedAnimation<Color>(
                ParentThemeColors.pinkDark,
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: isCurrent ? 24 : 8,
                decoration: BoxDecoration(
                  color: isCompleted || isCurrent
                      ? ParentThemeColors.pinkDark
                      : ParentThemeColors.skyBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildFamilyDetailsStep();
      case 2:
        return _buildPreferencesStep();
      case 3:
        return _buildDocumentUploadStep();
      case 4:
        return _buildReviewStep();
      default:
        return _buildDocumentUploadStep();
    }
  }

  Widget _buildPersonalInfoStep() {
    return _buildStepCard(
      children: [
        _buildTextField(
          label: 'Full Name',
          hint: 'Enter full name as per ID',
          icon: Icons.person_outline,
          controller: _fullNameController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Email Address',
          hint: 'your.email@example.com',
          icon: Icons.email_outlined,
          controller: _emailController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Phone Number',
          hint: '10-digit mobile number',
          icon: Icons.phone_outlined,
          controller: _phoneController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Annual Income',
          hint: 'Min ₹1,00,000',
          icon: Icons.account_balance_wallet_outlined,
          controller: _incomeController,
        ),
      ],
    );
  }

  Widget _buildFamilyDetailsStep() {
    return _buildStepCard(
      children: [
        _buildTextField(
          label: 'Marital Status',
          hint: 'Select status',
          icon: Icons.favorite_outline,
          initialValue: 'Married',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Spouse Name',
          hint: 'Enter spouse name',
          icon: Icons.person_outline,
          initialValue: 'Michael Mitchell',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Number of Children',
          hint: '0',
          icon: Icons.child_care,
          initialValue: '1',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Home Address',
          hint: 'Full address',
          icon: Icons.home_outlined,
          initialValue: 'Hadapsar, Pune, Maharashtra',
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildPreferencesStep() {
    return _buildStepCard(
      children: [
        _buildTextField(
          label: 'Preferred Child Age',
          hint: 'Age range (e.g., 0-2 years)',
          icon: Icons.child_friendly,
          initialValue: '0-3 years',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Gender Preference',
          hint: 'Select preference',
          icon: Icons.wc,
          initialValue: 'Female',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Special Needs Acceptance',
          hint: 'Yes/No',
          icon: Icons.accessibility_new,
          initialValue: 'Open to discussion',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Additional Notes',
          hint: 'Any specific preferences or concerns',
          icon: Icons.note_outlined,
          initialValue:
              'Looking forward to welcoming a girl child into our family.',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildDocumentUploadStep() {
    return Column(
      children: _documentsUploaded.entries.map((entry) {
        return _buildDocumentCard(
          docType: entry.key,
          isUploaded: entry.value,
          onUpload: () => _uploadDocument(entry.key),
        );
      }).toList(),
    );
  }

  Widget _buildReviewStep() {
    return _buildStepCard(
      children: [
        _buildReviewItem('Full Name', 'Sarah Mitchell'),
        _buildReviewItem('Email', 'sarah.mitchell@example.com'),
        _buildReviewItem('Phone', '9876509999'),
        _buildReviewItem('Marital Status', 'Married'),
        _buildReviewItem('Spouse', 'Michael Mitchell'),
        _buildReviewItem('Children', '1'),
        _buildReviewItem('Address', 'Hadapsar, Pune, Maharashtra'),
        _buildReviewItem('Preferred Age', '0-3 years'),
        _buildReviewItem('Gender Preference', 'Female'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ParentThemeColors.skyBlue.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ParentThemeColors.primaryBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: ParentThemeColors.primaryBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please review all information carefully before submitting.',
                  style: TextStyle(
                    fontSize: 13,
                    color: ParentThemeColors.textMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ParentThemeColors.skyBlue.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    String? initialValue,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: ParentThemeColors.primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ParentThemeColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ParentThemeColors.primaryBlue,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required String docType,
    required bool isUploaded,
    required VoidCallback onUpload,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUploaded
              ? ParentThemeColors.successGreen.withValues(alpha: 0.3)
              : ParentThemeColors.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.primaryBlue.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUploaded
                      ? ParentThemeColors.successGreen.withValues(alpha: 0.1)
                      : ParentThemeColors.skyBlue.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isUploaded ? Icons.description : Icons.badge,
                  color: isUploaded
                      ? ParentThemeColors.successGreen
                      : ParentThemeColors.textMid,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      docType,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ParentThemeColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isUploaded
                          ? 'Uploaded successfully'
                          : 'Required document',
                      style: TextStyle(
                        fontSize: 12,
                        color: ParentThemeColors.textMid,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isUploaded ? Icons.check_circle : Icons.cloud_upload_outlined,
                color: isUploaded
                    ? ParentThemeColors.successGreen
                    : ParentThemeColors.textSoft,
              ),
            ],
          ),
          if (!isUploaded) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: ParentThemeColors.borderColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onUpload,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Document'),
                        style: TextButton.styleFrom(
                          foregroundColor: ParentThemeColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: ParentThemeColors.textMid,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: ParentThemeColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.textDark.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: ParentThemeColors.primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: ParentThemeColors.primaryBlue,
                foregroundColor: ParentThemeColors.pureWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _currentStep == _totalSteps - 1
                          ? 'Submit Application'
                          : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Personal Information';
      case 1:
        return 'Family Details';
      case 2:
        return 'Adoption Preferences';
      case 3:
        return 'Document Upload';
      case 4:
        return 'Review & Submit';
      default:
        return 'Registration';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Your personal details';
      case 1:
        return 'About your family';
      case 2:
        return 'Your preferences';
      case 3:
        return 'Finalizing verification';
      case 4:
        return 'Final review';
      default:
        return 'Complete your profile';
    }
  }
}
