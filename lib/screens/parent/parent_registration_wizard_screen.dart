import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/route_names.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/parent_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/error_popup.dart';

class ParentRegistrationWizardScreen extends StatefulWidget {
  const ParentRegistrationWizardScreen({super.key});

  @override
  State<ParentRegistrationWizardScreen> createState() =>
      _ParentRegistrationWizardScreenState();
}

class _ParentRegistrationWizardScreenState
    extends State<ParentRegistrationWizardScreen> {
  static const LatLng _defaultMapCenter = LatLng(18.5204, 73.8567);

  static const List<String> _requiredDocuments = [
    'Government ID',
    'Income Proof',
    'Medical Certificate',
    'Police Verification',
    'Residence Proof',
  ];

  int _currentStep = 0;
  final int _totalSteps = 5;
  bool _isSubmitting = false;

  final _fullNameController = TextEditingController(text: 'Rahul Deshmukh');
  final _emailController = TextEditingController(
    text: 'parent.applicant@navjeevan.app',
  );
  final _phoneController = TextEditingController(text: '9876501234');
  final _incomeController = TextEditingController(text: '850000');
  final _otherRegionController = TextEditingController(text: 'Hadapsar');
  final _spouseNameController = TextEditingController(text: 'Neha Deshmukh');
  final _existingChildrenController = TextEditingController(text: '0');
  final _addressController = TextEditingController(
    text: 'Magarpatta City, Hadapsar, Pune',
  );
  final _preferredChildAgeController = TextEditingController(text: '1-4 years');
  final _requestedChildrenController = TextEditingController(text: '1');
  final _additionalNotesController = TextEditingController(
    text: 'Prepared for counseling and home verification visits.',
  );

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

  final List<String> _maritalStatuses = const [
    'Married',
    'Single',
    'Divorced',
    'Widowed',
  ];

  final List<String> _genderPreferences = const [
    'No preference',
    'Female',
    'Male',
  ];

  final List<String> _specialNeedsOptions = const [
    'Open to discussion',
    'Yes',
    'No',
  ];

  String? _selectedRegion = 'Hadapsar';
  String _selectedMaritalStatus = 'Married';
  String _selectedGenderPreference = 'No preference';
  String _selectedSpecialNeedsOption = 'Open to discussion';

  final Map<String, String> _documentPaths = <String, String>{};
  final Map<String, String> _documentNames = <String, String>{};
  final Map<String, Uint8List> _documentBytes = <String, Uint8List>{};
  LatLng? _selectedHomeCoordinates;

  final List<_MapSuggestion> _locationSuggestions = const [
    _MapSuggestion(
      label: 'Pune Central, Maharashtra',
      coordinates: LatLng(18.5204, 73.8567),
    ),
    _MapSuggestion(
      label: 'Hadapsar, Pune, Maharashtra',
      coordinates: LatLng(18.5089, 73.9259),
    ),
    _MapSuggestion(
      label: 'Aundh, Pune, Maharashtra',
      coordinates: LatLng(18.558, 73.8075),
    ),
    _MapSuggestion(
      label: 'Pimpri, Pune, Maharashtra',
      coordinates: LatLng(18.6298, 73.7997),
    ),
    _MapSuggestion(
      label: 'Viman Nagar, Pune, Maharashtra',
      coordinates: LatLng(18.5679, 73.9143),
    ),
    _MapSuggestion(
      label: 'Hinjewadi, Pune, Maharashtra',
      coordinates: LatLng(18.5913, 73.7389),
    ),
    _MapSuggestion(
      label: 'Baner, Pune, Maharashtra',
      coordinates: LatLng(18.559, 73.7797),
    ),
    _MapSuggestion(
      label: 'Kothrud, Pune, Maharashtra',
      coordinates: LatLng(18.5074, 73.8077),
    ),
  ];

  bool get _isOtherRegionSelected => _selectedRegion == 'Other';

  String? get _effectiveRegion {
    if (_isOtherRegionSelected) {
      final custom = _otherRegionController.text.trim();
      return custom.isEmpty ? null : custom;
    }
    return _selectedRegion;
  }

  double get _progressPercentage => ((_currentStep + 1) / _totalSteps) * 100;

  @override
  void initState() {
    super.initState();
    _selectedHomeCoordinates = _defaultMapCenter;
    final currentUser = FirebaseService.instance.currentUser;
    _emailController.text =
        currentUser?.email?.trim().isNotEmpty == true
        ? currentUser!.email!
        : _emailController.text;
    _fullNameController.text =
        currentUser?.displayName?.trim().isNotEmpty == true
        ? currentUser!.displayName!
        : _fullNameController.text;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _incomeController.dispose();
    _otherRegionController.dispose();
    _spouseNameController.dispose();
    _existingChildrenController.dispose();
    _addressController.dispose();
    _preferredChildAgeController.dispose();
    _requestedChildrenController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  void _nextStep() {
    final validationMessage = _validateStep(_currentStep);
    if (validationMessage != null) {
      showErrorBottomPopup(context, validationMessage);
      return;
    }

    if (_currentStep == _totalSteps - 1) {
      _submitApplication();
      return;
    }

    setState(() => _currentStep++);
  }

  String? _validateStep(int step) {
    switch (step) {
      case 0:
        if (_fullNameController.text.trim().isEmpty) {
          return 'Enter the parent full name.';
        }
        if (_emailController.text.trim().isEmpty ||
            !_emailController.text.contains('@')) {
          return 'Enter a valid email address.';
        }
        if (!RegExp(r'^\d{10}$').hasMatch(_phoneController.text.trim())) {
          return 'Enter a valid 10-digit phone number (digits only).';
        }
        final regionError = NavJeevanValidator.validateRegion(_effectiveRegion);
        if (regionError != null) {
          return regionError;
        }
        final incomeError = NavJeevanValidator.validateAnnualIncome(
          _incomeController.text,
        );
        if (incomeError != null) {
          return incomeError;
        }
        return null;
      case 1:
        if (_selectedMaritalStatus == 'Married' &&
            _spouseNameController.text.trim().isEmpty) {
          return 'Enter spouse name for married applicants.';
        }
        if (_addressController.text.trim().isEmpty ||
            _selectedHomeCoordinates == null) {
          return 'Select the home address from the map picker.';
        }
        return null;
      case 2:
        if (_preferredChildAgeController.text.trim().isEmpty) {
          return 'Enter preferred child age range.';
        }
        final requestedChildren =
            int.tryParse(_requestedChildrenController.text.trim()) ?? 0;
        if (requestedChildren <= 0) {
          return 'Requested child count must be at least 1.';
        }
        return null;
      case 3:
        final missingDocs = _requiredDocuments
            .where((doc) => !_documentPaths.containsKey(doc))
            .toList();
        if (missingDocs.isNotEmpty) {
          return 'Upload all required documents before continuing.';
        }
        return null;
      default:
        return null;
    }
  }

  Future<void> _submitApplication() async {
    setState(() => _isSubmitting = true);

    try {
      await FirebaseService.instance.submitAdoptionApplication(
        familyName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        region: _effectiveRegion!,
        annualIncome: double.tryParse(_incomeController.text.trim()) ?? 0,
        maritalStatus: _selectedMaritalStatus,
        spouseName: _spouseNameController.text.trim(),
        existingChildrenCount:
            int.tryParse(_existingChildrenController.text.trim()) ?? 0,
        address: _addressController.text.trim(),
        requestedChildrenCount:
            int.tryParse(_requestedChildrenController.text.trim()) ?? 1,
        preferredChildAge: _preferredChildAgeController.text.trim(),
        genderPreference: _selectedGenderPreference,
        specialNeedsAcceptance: _selectedSpecialNeedsOption,
        additionalNotes: _additionalNotesController.text.trim(),
        homeLatitude: _selectedHomeCoordinates?.latitude,
        homeLongitude: _selectedHomeCoordinates?.longitude,
        documentPaths: _documentPaths,
        documentBytes: _documentBytes,
        documentFileNames: _documentNames,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted with documents.'),
          backgroundColor: ParentThemeColors.successGreen,
        ),
      );
      context.go(NavJeevanRoutes.parentVerificationStatus);
    } catch (error) {
      if (mounted) {
        showErrorBottomPopup(context, 'Failed to submit application: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _uploadDocument(String docType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null) {
        return;
      }

      final selectedFile = result.files.single;
      if (selectedFile.path == null && selectedFile.bytes == null) {
        if (mounted) {
          showErrorBottomPopup(
            context,
            'Selected file could not be read from device storage. Please choose another file.',
          );
        }
        return;
      }

      setState(() {
        _documentPaths[docType] = selectedFile.path ?? '';
        _documentNames[docType] = selectedFile.name;
        if (selectedFile.bytes != null) {
          _documentBytes[docType] = selectedFile.bytes!;
        }
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$docType attached: ${selectedFile.name}'),
          backgroundColor: ParentThemeColors.successGreen,
        ),
      );
    } catch (error) {
      if (mounted) {
        showErrorBottomPopup(context, 'Unable to open device storage: $error');
      }
    }
  }

  Future<String> _resolveAddressFromCoordinates(LatLng coordinates) async {
    try {
      final places = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );
      if (places.isEmpty) {
        return '${coordinates.latitude.toStringAsFixed(5)}, ${coordinates.longitude.toStringAsFixed(5)}';
      }

      final place = places.first;
      final pieces = <String>[
        if ((place.name ?? '').trim().isNotEmpty) place.name!.trim(),
        if ((place.street ?? '').trim().isNotEmpty) place.street!.trim(),
        if ((place.subLocality ?? '').trim().isNotEmpty)
          place.subLocality!.trim(),
        if ((place.locality ?? '').trim().isNotEmpty) place.locality!.trim(),
        if ((place.administrativeArea ?? '').trim().isNotEmpty)
          place.administrativeArea!.trim(),
        if ((place.postalCode ?? '').trim().isNotEmpty)
          place.postalCode!.trim(),
      ];

      if (pieces.isEmpty) {
        return '${coordinates.latitude.toStringAsFixed(5)}, ${coordinates.longitude.toStringAsFixed(5)}';
      }

      return pieces.toSet().join(', ');
    } catch (_) {
      return '${coordinates.latitude.toStringAsFixed(5)}, ${coordinates.longitude.toStringAsFixed(5)}';
    }
  }

  Future<LatLng> _getCurrentDeviceLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError(
        'Location services are disabled. Enable GPS and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission was denied.');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LatLng(position.latitude, position.longitude);
  }

  Future<void> _openAddressPicker() async {
    final searchController = TextEditingController();
    GoogleMapController? mapController;
    LatLng selectedCoordinates = _selectedHomeCoordinates ?? _defaultMapCenter;
    String selectedAddress = _addressController.text.trim();

    final picked = await showDialog<_PickedAddressResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final query = searchController.text.trim().toLowerCase();
            final filteredSuggestions = _locationSuggestions
                .where(
                  (suggestion) =>
                      query.isEmpty || suggestion.label.toLowerCase().contains(query),
                )
                .toList();

            return Dialog(
              insetPadding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 560,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Select Home Location',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: ParentThemeColors.textDark,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search location suggestion',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                        child: TextButton.icon(
                          onPressed: () async {
                            try {
                              final currentCoordinates =
                                  await _getCurrentDeviceLocation();
                              final resolvedAddress =
                                  await _resolveAddressFromCoordinates(
                                currentCoordinates,
                              );

                              if (!mounted) {
                                return;
                              }

                              setDialogState(() {
                                selectedCoordinates = currentCoordinates;
                                selectedAddress = resolvedAddress;
                              });

                              mapController?.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  CameraPosition(
                                    target: currentCoordinates,
                                    zoom: 16,
                                  ),
                                ),
                              );
                            } catch (error) {
                              if (!mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.my_location,
                            size: 16,
                            color: ParentThemeColors.primaryBlue,
                          ),
                          label: const Text(
                            'Use current location',
                            style: TextStyle(
                              color: ParentThemeColors.primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final suggestion = filteredSuggestions[index];
                          return InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedCoordinates = suggestion.coordinates;
                                selectedAddress = suggestion.label;
                              });
                              mapController?.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  CameraPosition(
                                    target: suggestion.coordinates,
                                    zoom: 15.0,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 220,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: ParentThemeColors.skyBlue.withValues(
                                  alpha: 0.25,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ParentThemeColors.skyBlue,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: ParentThemeColors.primaryBlue,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      suggestion.label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemCount: filteredSuggestions.length,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: selectedCoordinates,
                              zoom: 14,
                            ),
                            onMapCreated: (controller) {
                              mapController = controller;
                            },
                            markers: {
                              Marker(
                                markerId: const MarkerId('home-location'),
                                position: selectedCoordinates,
                                infoWindow: const InfoWindow(
                                  title: 'Selected Home Location',
                                ),
                              ),
                            },
                            onTap: (coordinates) async {
                              setDialogState(() {
                                selectedCoordinates = coordinates;
                              });
                              final resolvedAddress =
                                  await _resolveAddressFromCoordinates(
                                coordinates,
                              );
                              if (!mounted) {
                                return;
                              }
                              setDialogState(() {
                                selectedAddress = resolvedAddress;
                              });
                            },
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: true,
                            mapToolbarEnabled: false,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected Address',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ParentThemeColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedAddress.isEmpty
                                ? 'Tap on map or choose a suggestion'
                                : selectedAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ParentThemeColors.textMid,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: selectedAddress.isEmpty
                                      ? null
                                      : () {
                                          Navigator.of(dialogContext).pop(
                                            _PickedAddressResult(
                                              address: selectedAddress,
                                              coordinates: selectedCoordinates,
                                            ),
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        ParentThemeColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Use this location'),
                                ),
                              ),
                            ],
                          ),
                        ],
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

    searchController.dispose();

    if (picked == null) {
      return;
    }

    setState(() {
      _addressController.text = picked.address;
      _selectedHomeCoordinates = picked.coordinates;
    });
  }

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
          const Expanded(
            child: Text(
              'Parent Registration',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ParentThemeColors.textDark,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ParentThemeColors.skyBlue.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Step ${_currentStep + 1}/$_totalSteps',
              style: const TextStyle(
                color: ParentThemeColors.primaryBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
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
            _getStepSubtitle(),
            style: TextStyle(fontSize: 13, color: ParentThemeColors.textMid),
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
          Text(
            '${_progressPercentage.toInt()}% complete',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: ParentThemeColors.textMid,
            ),
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
        return const SizedBox.shrink();
    }
  }

  Widget _buildPersonalInfoStep() {
    return _buildStepCard(
      children: [
        _buildTextField(
          label: 'Parent Full Name',
          hint: 'Enter full legal name',
          icon: Icons.person_outline,
          controller: _fullNameController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Email Address',
          hint: 'name@example.com',
          icon: Icons.email_outlined,
          controller: _emailController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Phone Number',
          hint: '10-digit mobile number',
          icon: Icons.phone_outlined,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Current Region',
          icon: Icons.location_on_outlined,
          value: _selectedRegion,
          items: _regions,
          onChanged: (value) {
            setState(() {
              _selectedRegion = value;
              if (!_isOtherRegionSelected) {
                _otherRegionController.clear();
              }
            });
          },
        ),
        if (_isOtherRegionSelected) ...[
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Specify Region',
            hint: 'Enter your city / region',
            icon: Icons.edit_location_alt_outlined,
            controller: _otherRegionController,
          ),
        ],
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Annual Household Income',
          hint: 'Example: 850000',
          icon: Icons.account_balance_wallet_outlined,
          controller: _incomeController,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildFamilyDetailsStep() {
    return _buildStepCard(
      children: [
        _buildDropdownField(
          label: 'Marital Status',
          icon: Icons.favorite_outline,
          value: _selectedMaritalStatus,
          items: _maritalStatuses,
          onChanged: (value) {
            setState(() {
              _selectedMaritalStatus = value ?? _selectedMaritalStatus;
              if (_selectedMaritalStatus != 'Married') {
                _spouseNameController.clear();
              }
            });
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Spouse Name',
          hint: 'Leave blank if not applicable',
          icon: Icons.people_outline,
          controller: _spouseNameController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Existing Children Count',
          hint: '0',
          icon: Icons.child_care,
          controller: _existingChildrenController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildAddressPickerField(),
      ],
    );
  }

  Widget _buildAddressPickerField() {
    final hasSelection = _addressController.text.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasSelection
              ? ParentThemeColors.primaryBlue.withValues(alpha: 0.4)
              : ParentThemeColors.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.home_outlined,
                color: ParentThemeColors.primaryBlue,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Home Address (Map Selection)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ParentThemeColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasSelection
                ? _addressController.text.trim()
                : 'No location selected. Tap below to choose from map suggestions.',
            style: TextStyle(
              color: hasSelection
                  ? ParentThemeColors.textDark
                  : ParentThemeColors.textMid,
            ),
          ),
          if (_selectedHomeCoordinates != null) ...[
            const SizedBox(height: 6),
            Text(
              'Lat: ${_selectedHomeCoordinates!.latitude.toStringAsFixed(5)}, Lng: ${_selectedHomeCoordinates!.longitude.toStringAsFixed(5)}',
              style: const TextStyle(
                color: ParentThemeColors.textMid,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openAddressPicker,
              icon: Icon(
                hasSelection ? Icons.edit_location_alt : Icons.map_outlined,
                color: ParentThemeColors.primaryBlue,
              ),
              label: Text(
                hasSelection ? 'Change location' : 'Pick location on map',
                style: const TextStyle(
                  color: ParentThemeColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: ParentThemeColors.primaryBlue.withValues(alpha: 0.45),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesStep() {
    return _buildStepCard(
      children: [
        _buildTextField(
          label: 'Preferred Child Age Range',
          hint: 'Example: 0-3 years',
          icon: Icons.child_friendly,
          controller: _preferredChildAgeController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Requested Child Count',
          hint: '1',
          icon: Icons.format_list_numbered,
          controller: _requestedChildrenController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Gender Preference',
          icon: Icons.wc,
          value: _selectedGenderPreference,
          items: _genderPreferences,
          onChanged: (value) {
            setState(() {
              _selectedGenderPreference = value ?? _selectedGenderPreference;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Special Needs Acceptance',
          icon: Icons.accessibility_new,
          value: _selectedSpecialNeedsOption,
          items: _specialNeedsOptions,
          onChanged: (value) {
            setState(() {
              _selectedSpecialNeedsOption =
                  value ?? _selectedSpecialNeedsOption;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Additional Notes',
          hint: 'Share adoption preferences or important details',
          icon: Icons.note_outlined,
          controller: _additionalNotesController,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildDocumentUploadStep() {
    return Column(
      children: _requiredDocuments.map((docType) {
        final fileName = _documentNames[docType];
        return _buildDocumentCard(
          docType: docType,
          fileName: fileName,
          isUploaded: fileName != null,
          onUpload: () => _uploadDocument(docType),
        );
      }).toList(),
    );
  }

  Widget _buildReviewStep() {
    return _buildStepCard(
      children: [
        _buildReviewItem('Name', _fullNameController.text.trim()),
        _buildReviewItem('Email', _emailController.text.trim()),
        _buildReviewItem('Phone', _phoneController.text.trim()),
        _buildReviewItem('Region', _effectiveRegion ?? '-'),
        _buildReviewItem('Income', '₹${_incomeController.text.trim()}'),
        _buildReviewItem('Marital Status', _selectedMaritalStatus),
        _buildReviewItem(
          'Spouse',
          _spouseNameController.text.trim().isEmpty
              ? 'Not provided'
              : _spouseNameController.text.trim(),
        ),
        _buildReviewItem(
          'Existing Children',
          _existingChildrenController.text.trim(),
        ),
        _buildReviewItem('Address', _addressController.text.trim()),
        _buildReviewItem(
          'Requested Child Count',
          _requestedChildrenController.text.trim(),
        ),
        _buildReviewItem(
          'Preferred Age',
          _preferredChildAgeController.text.trim(),
        ),
        _buildReviewItem('Gender Preference', _selectedGenderPreference),
        _buildReviewItem('Special Needs', _selectedSpecialNeedsOption),
        _buildReviewItem(
          'Documents Ready',
          '${_documentPaths.length}/${_requiredDocuments.length}',
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ParentThemeColors.skyBlue.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'On submission, every uploaded document is saved to secure Cloudinary storage with Firestore metadata and becomes visible to the admin verification queue.',
            style: TextStyle(
              color: ParentThemeColors.textMid,
              fontWeight: FontWeight.w600,
            ),
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
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
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

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
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
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
    );
  }

  Widget _buildDocumentCard({
    required String docType,
    required bool isUploaded,
    required VoidCallback onUpload,
    String? fileName,
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUploaded
                      ? ParentThemeColors.successGreen.withValues(alpha: 0.12)
                      : ParentThemeColors.skyBlue.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isUploaded ? Icons.insert_drive_file : Icons.upload_file,
                  color: isUploaded
                      ? ParentThemeColors.successGreen
                      : ParentThemeColors.primaryBlue,
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
                    const SizedBox(height: 4),
                    Text(
                      fileName ??
                          'Accepted: PDF, DOC, DOCX, JPG, JPEG, PNG from device storage',
                      style: TextStyle(
                        color: ParentThemeColors.textMid,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isUploaded ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isUploaded
                    ? ParentThemeColors.successGreen
                    : ParentThemeColors.textSoft,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onUpload,
              icon: Icon(isUploaded ? Icons.refresh : Icons.folder_open),
              label: Text(isUploaded ? 'Replace file' : 'Choose file'),
              style: TextButton.styleFrom(
                foregroundColor: ParentThemeColors.primaryBlue,
              ),
            ),
          ),
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
            width: 150,
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
              value.isEmpty ? '-' : value,
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
            color: ParentThemeColors.textDark.withValues(alpha: 0.08),
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
        return 'Personal information';
      case 1:
        return 'Family details';
      case 2:
        return 'Adoption preferences';
      case 3:
        return 'Upload documents';
      case 4:
        return 'Review and submit';
      default:
        return 'Registration';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Collect contact, income, and region details.';
      case 1:
        return 'Capture address and family background information.';
      case 2:
        return 'Specify the requested child count and preferences.';
      case 3:
        return 'Pick files directly from device storage in multiple formats.';
      case 4:
        return 'Review the final data before sending it for verification.';
      default:
        return '';
    }
  }
}

class _MapSuggestion {
  const _MapSuggestion({required this.label, required this.coordinates});

  final String label;
  final LatLng coordinates;
}

class _PickedAddressResult {
  const _PickedAddressResult({
    required this.address,
    required this.coordinates,
  });

  final String address;
  final LatLng coordinates;
}
