import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/parent_colors.dart';
import '../../core/constants/dummy_parent_data.dart';
import '../../core/services/parent_notification_preferences_store.dart';

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  bool _isEditMode = false;
  bool _notificationsEnabled = true;
  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, bool> _notificationPhasePrefs = {
    'request': true,
    'verification': true,
    'acceptance': true,
    'guidance': true,
    'supportCalls': true,
    'sessions': true,
  };
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentParent = DummyParentData.getCurrentParent();
    _phoneController.text = currentParent.contactPhone ?? '';
    _emailController.text = currentParent.email ?? '';
    _loadProfileNotificationPreferences();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        // Save changes
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: ParentThemeColors.successGreen,
          ),
        );
      }
    });
  }

  Future<void> _loadProfileNotificationPreferences() async {
    final stored =
        await ParentNotificationPreferencesStore.loadProfilePreferences();
    if (!mounted) return;

    final loadedPrefs = (stored['prefs'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as bool),
    );

    setState(() {
      _notificationsEnabled = stored['enabled'] as bool;
      _notificationPhasePrefs
        ..clear()
        ..addAll(loadedPrefs);
    });
  }

  Future<void> _saveProfileNotificationPreferences() async {
    await ParentNotificationPreferencesStore.saveProfilePreferences(
      enabled: _notificationsEnabled,
      prefs: Map<String, bool>.from(_notificationPhasePrefs),
    );
  }

  void _reuploadDocument(String docType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ParentThemeColors.pureWhite,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Capture from Camera'),
              subtitle: const Text('Image capture for document upload'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadDocument(
                  docType: docType,
                  source: 'Camera',
                  mediaType: 'image',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Select Image from Gallery'),
              subtitle: const Text('JPG, PNG and other image files'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadDocument(
                  docType: docType,
                  source: 'Gallery',
                  mediaType: 'image',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Select Video'),
              subtitle: const Text('MP4, MOV and other video files'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadDocument(
                  docType: docType,
                  source: 'Gallery',
                  mediaType: 'video',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.audio_file_outlined),
              title: const Text('Select Audio'),
              subtitle: const Text('MP3, WAV, AAC and other audio files'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadDocument(
                  docType: docType,
                  source: 'Device',
                  mediaType: 'audio',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Browse Documents / Any File'),
              subtitle: const Text(
                'Access all system files and media resources',
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadDocument(
                  docType: docType,
                  source: 'File System',
                  mediaType: 'any',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadDocument({
    required String docType,
    required String source,
    required String mediaType,
  }) async {
    String? selectedName;

    try {
      if (mediaType == 'image') {
        final ImageSource imageSource = source == 'Camera'
            ? ImageSource.camera
            : ImageSource.gallery;
        final XFile? file = await _imagePicker.pickImage(source: imageSource);
        selectedName = file?.name;
      } else if (mediaType == 'video') {
        final XFile? file = await _imagePicker.pickVideo(
          source: ImageSource.gallery,
        );
        selectedName = file?.name;
      } else if (mediaType == 'audio') {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['mp3', 'wav', 'aac', 'm4a'],
        );
        selectedName = result?.files.single.name;
      } else {
        final result = await FilePicker.platform.pickFiles(type: FileType.any);
        selectedName = result?.files.single.name;
      }

      if (!mounted) return;

      if (selectedName == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No file selected.')));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$docType uploaded from $source: $selectedName'),
          backgroundColor: ParentThemeColors.successGreen,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to access selected source right now.'),
          backgroundColor: ParentThemeColors.errorRed,
        ),
      );
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: ParentThemeColors.pureWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications by Adoption Phase',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ParentThemeColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _notificationsEnabled,
                      title: const Text('Enable Notifications'),
                      subtitle: const Text(
                        'Master control for profile notifications',
                      ),
                      activeThumbColor: ParentThemeColors.primaryBlue,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                        _saveProfileNotificationPreferences();
                        setModalState(() {});
                      },
                    ),
                    const Divider(),
                    ...[
                      ['request', 'Request Updates'],
                      ['verification', 'Verification Alerts'],
                      ['acceptance', 'Acceptance Milestones'],
                      ['guidance', 'Guidance Suggestions'],
                      ['supportCalls', 'Support Calls'],
                      ['sessions', 'Counseling Sessions'],
                    ].map((entry) {
                      final key = entry[0];
                      final label = entry[1];
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _notificationPhasePrefs[key] ?? false,
                        title: Text(label),
                        activeThumbColor: ParentThemeColors.primaryBlue,
                        onChanged: _notificationsEnabled
                            ? (value) {
                                setState(() {
                                  _notificationPhasePrefs[key] = value;
                                });
                                _saveProfileNotificationPreferences();
                                setModalState(() {});
                              }
                            : null,
                      );
                    }),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _saveProfileNotificationPreferences();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Notification preferences updated.',
                              ),
                              backgroundColor: ParentThemeColors.successGreen,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ParentThemeColors.primaryBlue,
                        ),
                        child: const Text('Save Preferences'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentParent = DummyParentData.getCurrentParent();
    final documents = DummyParentData.sampleDocuments;

    return Scaffold(
      backgroundColor: ParentThemeColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, currentParent),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(currentParent),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Personal Details'),
                    const SizedBox(height: 12),
                    _buildPersonalDetailsCard(currentParent),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Uploaded Documents'),
                    const SizedBox(height: 12),
                    ...documents.map((doc) => _buildDocumentCard(doc)),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Application Settings'),
                    const SizedBox(height: 12),
                    _buildSettingsCard(context),
                    const SizedBox(height: 16),
                    _buildLogoutButton(context),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic parent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ParentThemeColors.trustGradient,
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: ParentThemeColors.pureWhite,
            ),
            onPressed: () => context.pop(),
          ),
          const Text(
            'My Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ParentThemeColors.pureWhite,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isEditMode ? Icons.save : Icons.edit,
              color: ParentThemeColors.pureWhite,
            ),
            onPressed: _toggleEditMode,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(dynamic parent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ParentThemeColors.borderColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.primaryBlue.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: ParentThemeColors.trustGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ParentThemeColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.family_restroom,
              color: ParentThemeColors.pureWhite,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            parent.familyName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ParentThemeColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Family ID: ${parent.familyId}',
            style: TextStyle(fontSize: 14, color: ParentThemeColors.textMid),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProfileStat(
                  'Region',
                  parent.region,
                  Icons.location_on,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: ParentThemeColors.borderColor,
              ),
              Expanded(
                child: _buildProfileStat(
                  'Status',
                  parent.adoptionStatus,
                  Icons.verified,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: ParentThemeColors.borderColor,
              ),
              Expanded(
                child: _buildProfileStat(
                  'Score',
                  '${parent.verificationScore}/100',
                  Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: ParentThemeColors.primaryBlue, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: ParentThemeColors.textMid),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: ParentThemeColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalDetailsCard(dynamic parent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isEditMode
              ? ParentThemeColors.primaryBlue
              : ParentThemeColors.borderColor.withValues(alpha: 0.5),
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
          _buildDetailRow(
            'Family Name',
            parent.familyName,
            Icons.people,
            isEditable: false,
          ),
          const Divider(height: 24),
          _isEditMode
              ? _buildEditableRow('Phone', _phoneController, Icons.phone)
              : _buildDetailRow(
                  'Phone',
                  parent.contactPhone ?? 'Not provided',
                  Icons.phone,
                ),
          const Divider(height: 24),
          _isEditMode
              ? _buildEditableRow('Email', _emailController, Icons.email)
              : _buildDetailRow(
                  'Email',
                  parent.email ?? 'Not provided',
                  Icons.email,
                ),
          const Divider(height: 24),
          _buildDetailRow(
            'Region',
            parent.region,
            Icons.location_city,
            isEditable: false,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Income Level',
            parent.incomeLevel,
            Icons.account_balance_wallet,
            isEditable: false,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Children',
            '${parent.children}',
            Icons.child_care,
            isEditable: false,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Home Verified',
            parent.homeVerified ? 'Yes ✓' : 'Pending',
            Icons.home,
            isEditable: false,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Background Check',
            parent.backgroundCheck,
            Icons.verified_user,
            isEditable: false,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ParentThemeColors.skyBlue.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: ParentThemeColors.primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: ParentThemeColors.textMid,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: controller,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: ParentThemeColors.textDark,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: ParentThemeColors.primaryBlue,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: ParentThemeColors.primaryBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isEditable = true,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ParentThemeColors.skyBlue.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: ParentThemeColors.primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: ParentThemeColors.textMid,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: ParentThemeColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(dynamic doc) {
    final statusColors = {
      'Verified': ParentThemeColors.successGreen,
      'Pending Review': ParentThemeColors.warningOrange,
      'In Progress': ParentThemeColors.infoBlue,
    };

    final statusColor = statusColors[doc.status] ?? ParentThemeColors.textMid;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.description, color: statusColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.docType,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ParentThemeColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doc.fileName,
                  style: TextStyle(
                    fontSize: 12,
                    color: ParentThemeColors.textMid,
                  ),
                ),
                if (doc.remarks != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    doc.remarks!,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  doc.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${doc.uploadDate.day}/${doc.uploadDate.month}/${doc.uploadDate.year}',
                style: TextStyle(
                  fontSize: 10,
                  color: ParentThemeColors.textMid,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _reuploadDocument(doc.docType),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ParentThemeColors.primaryBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Re-upload',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ParentThemeColors.pureWhite,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ParentThemeColors.borderColor.withValues(alpha: 0.5),
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
          _buildSettingItem(
            context: context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: _showNotificationSettings,
          ),
          const Divider(height: 1),
          _buildSettingItem(
            context: context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy & Security',
            subtitle: 'Control your data and privacy',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening privacy settings...')),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingItem(
            context: context,
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening language settings...')),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingItem(
            context: context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help with your account',
            onTap: () {
              context.push(NavJeevanRoutes.parentSupport);
            },
          ),
          const Divider(height: 1),
          _buildSettingItem(
            context: context,
            icon: Icons.info_outline,
            title: 'About NavJeevan',
            subtitle: 'Version 1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'NavJeevan',
                applicationVersion: '1.0.0',
                applicationLegalese:
                    '© 2026 NavJeevan. All rights reserved.\n\nEmpowering families through secure and trusted adoption services.',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ParentThemeColors.skyBlue.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: ParentThemeColors.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: ParentThemeColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: ParentThemeColors.textMid,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: ParentThemeColors.textSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ParentThemeColors.errorRed.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.errorRed.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go(NavJeevanRoutes.roleSelect);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logged out successfully'),
                          backgroundColor: ParentThemeColors.successGreen,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ParentThemeColors.errorRed,
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: ParentThemeColors.errorRed),
                const SizedBox(width: 12),
                const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ParentThemeColors.errorRed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: ParentThemeColors.textMid,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            isActive: false,
            onTap: () => context.push(NavJeevanRoutes.parentSupport),
          ),
          _buildNavItem(
            context: context,
            icon: Icons.person,
            label: 'Profile',
            isActive: true,
            onTap: () {},
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
