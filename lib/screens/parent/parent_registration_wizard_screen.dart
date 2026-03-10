import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/dummy_parent_data.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/parent_colors.dart';

class ParentRegistrationWizardScreen extends StatefulWidget {
  const ParentRegistrationWizardScreen({super.key});

  @override
  State<ParentRegistrationWizardScreen> createState() =>
      _ParentRegistrationWizardScreenState();
}

class _ParentRegistrationWizardScreenState
    extends State<ParentRegistrationWizardScreen> {
  int _currentStep = 3; // Step 4 of 5 (0-indexed as 3)
  final int _totalSteps = 5;

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

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration Submitted Successfully!'),
          backgroundColor: ParentThemeColors.successGreen,
        ),
      );
      context.push(NavJeevanRoutes.parentVerificationStatus);
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
        color: ParentThemeColors.pureWhite.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(color: ParentThemeColors.skyBlue, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: ParentThemeColors.accentPink.withOpacity(0.3),
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
        border: Border.all(color: ParentThemeColors.skyBlue.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.primaryBlue.withOpacity(0.08),
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
                      color: ParentThemeColors.pinkDark.withOpacity(0.3),
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
          initialValue: 'Sarah Mitchell',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Email Address',
          hint: 'your.email@example.com',
          icon: Icons.email_outlined,
          initialValue: 'sarah.mitchell@example.com',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Phone Number',
          hint: '10-digit mobile number',
          icon: Icons.phone_outlined,
          initialValue: '9876509999',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Date of Birth',
          hint: 'DD/MM/YYYY',
          icon: Icons.calendar_today,
          initialValue: '15/08/1985',
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
            color: ParentThemeColors.skyBlue.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ParentThemeColors.primaryBlue.withOpacity(0.3),
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
        border: Border.all(color: ParentThemeColors.skyBlue.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.primaryBlue.withOpacity(0.08),
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
    String? initialValue,
    int maxLines = 1,
  }) {
    // Use TextFormField with initialValue (not a controller) to avoid
    // creating new TextEditingController instances on every rebuild,
    // which causes '_dependents.isEmpty' assertion failures and overflow.
    return TextFormField(
      initialValue: initialValue,
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
              ? ParentThemeColors.successGreen.withOpacity(0.3)
              : ParentThemeColors.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.primaryBlue.withOpacity(0.05),
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
                      ? ParentThemeColors.successGreen.withOpacity(0.1)
                      : ParentThemeColors.skyBlue.withOpacity(0.3),
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
                    color: ParentThemeColors.borderColor.withOpacity(0.3),
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
            color: ParentThemeColors.textDark.withOpacity(0.1),
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
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: ParentThemeColors.primaryBlue,
                foregroundColor: ParentThemeColors.pureWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
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
