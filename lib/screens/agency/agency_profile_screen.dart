import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_names.dart';
import '../../core/services/agency_notification_center.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/parent_colors.dart';

class AgencyProfileScreen extends StatefulWidget {
  const AgencyProfileScreen({super.key});

  @override
  State<AgencyProfileScreen> createState() => _AgencyProfileScreenState();
}

class _AgencyProfileScreenState extends State<AgencyProfileScreen> {
  final AgencyNotificationCenter _notifications = AgencyNotificationCenter.instance;
  bool _editMode = false;
  String _memberCategoryFilter = 'general';
  late final TextEditingController _nameController;
  late final TextEditingController _regController;
  late final TextEditingController _missionController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _hqController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Global Welfare Alliance Foundation');
    _regController = TextEditingController(text: 'RN-2023-001');
    _missionController = TextEditingController(
      text:
          'Dedicated to providing immediate welfare support and counseling to vulnerable families and mothers.',
    );
    _emailController = TextEditingController(text: 'contact@gwalliance.org');
    _phoneController = TextEditingController(text: '+91 9876543210');
    _hqController = TextEditingController(text: 'Pune, Maharashtra');
  }

  Future<void> _showCounselorFormSheet({
    String? counselorId,
    Map<String, dynamic>? existingMember,
  }) async {
    final isEditMode =
        counselorId != null && counselorId.trim().isNotEmpty && existingMember != null;

    final nameController = TextEditingController(
      text: (existingMember?['name'] ?? '').toString(),
    );
    final addressController = TextEditingController(
      text: (existingMember?['address'] ?? '').toString(),
    );
    final contactController = TextEditingController(
      text: (existingMember?['phone'] ?? '').toString(),
    );
    final experienceController = TextEditingController(
      text: (existingMember?['yearsExperience'] ?? '').toString(),
    );
    final expertiseController = TextEditingController(
      text: (existingMember?['expertiseDomain'] ?? existingMember?['specialty'] ?? '')
          .toString(),
    );
    final emailController = TextEditingController(
      text: (existingMember?['email'] ?? '').toString(),
    );

    final existingCategory =
        (existingMember?['category'] ?? 'general').toString().toLowerCase();
    String selectedCategory =
        ['general', 'legal', 'medical'].contains(existingCategory)
        ? existingCategory
        : 'general';
    Uint8List? selectedPhotoBytes;
    String? selectedPhotoName;
    final existingPhotoUrl = (existingMember?['image'] ?? '').toString();
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ParentThemeColors.pureWhite,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickPhoto() async {
              final fileResult = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
                withData: true,
              );

              if (fileResult == null || fileResult.files.single.bytes == null) {
                return;
              }

              setModalState(() {
                selectedPhotoBytes = fileResult.files.single.bytes;
                selectedPhotoName = fileResult.files.single.name;
              });
            }

            Future<void> submit() async {
              final name = nameController.text.trim();
              final address = addressController.text.trim();
              final contact = contactController.text.trim();
              final expertise = expertiseController.text.trim();
              final years = int.tryParse(experienceController.text.trim());
              final email = emailController.text.trim();

              if (name.isEmpty ||
                  address.isEmpty ||
                  contact.isEmpty ||
                  expertise.isEmpty ||
                  years == null ||
                  years < 0 ||
                  (!isEditMode &&
                      (selectedPhotoBytes == null ||
                          (selectedPhotoName ?? '').isEmpty))) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditMode
                          ? 'Please provide name, address, contact, experience, expertise and category.'
                          : 'Please provide name, address, contact, experience, expertise, category and photo.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setModalState(() => isSubmitting = true);

              try {
                String resultingCounselorId = counselorId ?? '';
                if (isEditMode) {
                  await FirebaseService.instance.updateAgencyCounselorProfile(
                  counselorId: counselorId,
                    name: name,
                    address: address,
                    contact: contact,
                    yearsExperience: years,
                    expertiseDomain: expertise,
                    category: selectedCategory,
                  status: (existingMember['status'] ?? 'available').toString(),
                    activeCases:
                    int.tryParse((existingMember['activeCases'] ?? 0).toString()) ??
                        0,
                    maxCases:
                    int.tryParse((existingMember['maxCases'] ?? 10).toString()) ??
                        10,
                    email: email.isEmpty ? null : email,
                    currentImageUrl: existingPhotoUrl,
                    photoBytes: selectedPhotoBytes,
                    photoFileName: selectedPhotoName,
                  );
                } else {
                  resultingCounselorId =
                      await FirebaseService.instance.addAgencyCounselorProfile(
                    name: name,
                    address: address,
                    contact: contact,
                    yearsExperience: years,
                    expertiseDomain: expertise,
                    category: selectedCategory,
                    photoBytes: selectedPhotoBytes!,
                    photoFileName: selectedPhotoName!,
                    email: email.isEmpty ? null : email,
                  );
                }

                if (!mounted) {
                  return;
                }

                _notifications.push(
                  title: isEditMode ? 'Counselor Updated' : 'Counselor Added',
                  message: isEditMode
                      ? '$name profile updated successfully.'
                      : '$name added to counselor directory ($resultingCounselorId).',
                  category: 'Profile',
                );

                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditMode
                          ? '$name updated successfully.'
                          : '$name added successfully.',
                    ),
                    backgroundColor: ParentThemeColors.successGreen,
                  ),
                );
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditMode
                          ? 'Failed to update counselor: $error'
                          : 'Failed to add counselor: $error',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (mounted) {
                  setModalState(() => isSubmitting = false);
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEditMode ? 'Edit Counselor Member' : 'Add New Counselor',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: contactController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Contact *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: experienceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Experience (years) *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: expertiseController,
                        decoration: const InputDecoration(
                          labelText: 'Expertise Domain *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: const [
                          DropdownMenuItem(value: 'general', child: Text('General')),
                          DropdownMenuItem(value: 'legal', child: Text('Legal')),
                          DropdownMenuItem(value: 'medical', child: Text('Medical')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() => selectedCategory = value);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isSubmitting ? null : pickPhoto,
                              icon: const Icon(Icons.photo_camera),
                              label: Text(
                                selectedPhotoName?.isNotEmpty == true
                                    ? 'Photo Selected'
                                    : isEditMode
                                        ? 'Replace Photo (Optional)'
                                        : 'Upload Photo *',
                              ),
                            ),
                          ),
                          if (selectedPhotoBytes != null) ...[
                            const SizedBox(width: 10),
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: MemoryImage(selectedPhotoBytes!),
                            ),
                          ] else if (existingPhotoUrl.isNotEmpty && isEditMode) ...[
                            const SizedBox(width: 10),
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: NetworkImage(existingPhotoUrl),
                            ),
                          ],
                        ],
                      ),
                      if ((selectedPhotoName ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            selectedPhotoName!,
                            style: const TextStyle(
                              color: ParentThemeColors.textMid,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting ? null : submit,
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: ParentThemeColors.pureWhite,
                                  ),
                                )
                              : const Icon(Icons.person_add),
                          label: Text(
                            isSubmitting
                                ? (isEditMode
                                      ? 'Updating Counselor...'
                                      : 'Adding Counselor...')
                                : (isEditMode ? 'Update Counselor' : 'Add Counselor'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEC5B13),
                            foregroundColor: ParentThemeColors.pureWhite,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    addressController.dispose();
    contactController.dispose();
    experienceController.dispose();
    expertiseController.dispose();
    emailController.dispose();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regController.dispose();
    _missionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _hqController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentThemeColors.pureWhite,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTopProfile(),
            const SizedBox(height: 20),
            _buildAgencyDetails(),
            const SizedBox(height: 16),
            _buildContactInfo(),
            const SizedBox(height: 16),
            _buildAccessControl(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go(NavJeevanRoutes.roleSelect),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEE2E2),
                foregroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                side: const BorderSide(color: Color(0xFFFECACA)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout from Agency'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: ParentThemeColors.pureWhite,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Agency Settings',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        IconButton(
          icon: Icon(_editMode ? Icons.save : Icons.edit),
          color: const Color(0xFFEC5B13),
          onPressed: () {
            setState(() => _editMode = !_editMode);
            if (!_editMode) {
              _notifications.push(
                title: 'Profile Updated',
                message: 'Agency profile details were saved successfully.',
                category: 'Profile',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Agency profile updated.')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildTopProfile() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F2FE), Color(0xFFFCE7F3)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: ParentThemeColors.primaryBlue,
            child: const Icon(Icons.apartment, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 10),
          const Text(
            'Global Welfare Alliance',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Non-Profit Organization • ID: NGO101',
            style: TextStyle(color: ParentThemeColors.textMid, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAgencyDetails() {
    return _sectionCard(
      title: 'Agency Details',
      children: [
        _field('Registration Name', _nameController),
        _field('Registration Number', _regController),
        _field('Mission Statement', _missionController, maxLines: 3),
      ],
    );
  }

  Widget _buildContactInfo() {
    return _sectionCard(
      title: 'Contact Information',
      children: [
        _field('Public Email', _emailController),
        _field('Support Line', _phoneController),
        _field('Headquarters', _hqController),
      ],
    );
  }

  Widget _buildAccessControl() {
    return _sectionCard(
      title: 'Access Control',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['general', 'legal', 'medical']
              .map(
                (category) => ChoiceChip(
                  label: Text(
                    '${category[0].toUpperCase()}${category.substring(1)}',
                  ),
                  selected: _memberCategoryFilter == category,
                  onSelected: (_) {
                    setState(() => _memberCategoryFilter = category);
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.instance.watchCounselorDirectory(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? <QueryDocumentSnapshot<Object?>>[];
            final members = docs
                .map(
                  (doc) => {
                    'id': doc.id,
                    'data': doc.data() as Map<String, dynamic>,
                  },
                )
                .where((member) {
                  final category =
                      (member['data'] as Map<String, dynamic>)['category']
                          ?.toString()
                          .toLowerCase() ??
                      'general';
                  return category == _memberCategoryFilter;
                })
                .toList();

            if (members.isEmpty) {
              return Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'No $_memberCategoryFilter counselors found. Add a new member in this category.',
                  style: TextStyle(
                    color: ParentThemeColors.textMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            return Column(
              children: members
                  .map(
                    (member) {
                      final memberData =
                          member['data'] as Map<String, dynamic>? ??
                          <String, dynamic>{};
                      final imageUrl = (memberData['image'] ?? '').toString();
                      final displayName =
                          (memberData['name'] ?? 'Counselor').toString();
                      final specialty =
                          (memberData['specialty'] ??
                                  memberData['expertiseDomain'] ??
                                  'Support')
                              .toString();
                      final category =
                          (memberData['category'] ?? 'general').toString();

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: ParentThemeColors.skyBlue,
                          backgroundImage:
                              imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                          child: imageUrl.isNotEmpty
                              ? null
                              : Text(
                                  displayName
                                      .split(' ')
                                      .map((w) => w.isEmpty ? '' : w[0])
                                      .take(2)
                                      .join()
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: ParentThemeColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        title: Text(displayName),
                        subtitle: Text('$specialty • $category'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ParentThemeColors.primaryBlue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Counselor',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit Member',
                              onPressed: () => _showCounselorFormSheet(
                                counselorId: (member['id'] ?? '').toString(),
                                existingMember: memberData,
                              ),
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Color(0xFFEC5B13),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                  .toList(),
            );
          },
        ),
        OutlinedButton.icon(
          onPressed: _showCounselorFormSheet,
          icon: const Icon(Icons.person_add),
          label: const Text('Add New Member'),
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ParentThemeColors.borderColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        enabled: _editMode,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: _editMode
              ? ParentThemeColors.pureWhite
              : ParentThemeColors.skyBlue.withValues(alpha: 0.15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        border: Border(
          top: BorderSide(
            color: ParentThemeColors.borderColor.withValues(alpha: 0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          _navItem(
            'Requests',
            Icons.assignment,
            false,
            () => context.go(NavJeevanRoutes.agencyRequestsDashboard),
          ),
          _navItem(
            'Welfare',
            Icons.health_and_safety,
            false,
            () => context.go(NavJeevanRoutes.agencyWelfareMonitoring),
          ),
          _navItem(
            'Counselors',
            Icons.groups,
            false,
            () => context.go(NavJeevanRoutes.agencyCounselorManagement),
          ),
          _navItem('Profile', Icons.person, true, () {}),
        ],
      ),
    );
  }

  Widget _navItem(
    String label,
    IconData icon,
    bool active,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active ? const Color(0xFFEC5B13) : ParentThemeColors.textMid,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  color: active ? const Color(0xFFEC5B13) : ParentThemeColors.textMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
