import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/constants/route_names.dart';
import '../../core/services/firebase_service.dart';
import '../../core/widgets/error_popup.dart';

class NgoSupportMapScreen extends StatefulWidget {
  const NgoSupportMapScreen({super.key});

  @override
  State<NgoSupportMapScreen> createState() => _NgoSupportMapScreenState();
}

class _NgoSupportMapScreenState extends State<NgoSupportMapScreen> {
  GoogleMapController? _mapController;
  Map<String, dynamic>? _selectedCenter;
  bool get _supportsNativeMap =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  final LatLng _center = const LatLng(18.5204, 73.8567); // Pune Center

  final List<Map<String, dynamic>> _centers = [
    {
      'ngoId': 'NGO101',
      'name': 'Snehalaya Child Support Center',
      'region': 'Hadapsar',
      'services': ['Counseling', 'Adoption Support'],
      'contact': '+91 9876543210',
      'rating': 4.5,
      'securityLevel': 'Green',
      'availability': '24x7 hotline',
      'emergencySupport': 'Immediate shelter available',
      'preferredContact': 'Phone / WhatsApp',
      'womenHelpline': '1091',
      'position': const LatLng(18.4966, 73.9419),
    },
    {
      'ngoId': 'NGO102',
      'name': 'Child Welfare Society Pune',
      'region': 'Shivajinagar',
      'services': ['Legal Guidance', 'Shelter'],
      'contact': '+91 9876543211',
      'rating': 4.3,
      'securityLevel': 'Blue',
      'availability': '8 AM - 10 PM',
      'emergencySupport': 'Legal response within 2 hours',
      'preferredContact': 'Phone / In-person',
      'womenHelpline': '181',
      'position': const LatLng(18.5308, 73.8475),
    },
    {
      'ngoId': 'NGO103',
      'name': 'Sakhi Women\'s Support NGO',
      'region': 'Katraj',
      'services': ['Counseling', 'Medical Support'],
      'contact': '+91 9876543212',
      'rating': 4.6,
      'securityLevel': 'Green',
      'availability': '24x7 counselor on call',
      'emergencySupport': 'Ambulance + hospital tie-up',
      'preferredContact': 'Phone / Video call',
      'womenHelpline': '112',
      'position': const LatLng(18.4575, 73.8580),
    },
    {
      'ngoId': 'NGO104',
      'name': 'Hope Adoption Services',
      'region': 'Wakad',
      'services': ['Adoption Processing', 'Family Verification'],
      'contact': '+91 9876543213',
      'rating': 4.4,
      'securityLevel': 'Red',
      'availability': '9 AM - 8 PM',
      'emergencySupport': 'Priority case escalation desk',
      'preferredContact': 'Phone / Office visit',
      'womenHelpline': '1098',
      'position': const LatLng(18.5995, 73.7627),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedCenter = _centers.first;
  }

  Set<Marker> get _markers => _centers.map((center) {
    final String securityLevel = center['securityLevel'] as String;
    return Marker(
      markerId: MarkerId(center['ngoId'] as String),
      position: center['position'] as LatLng,
      infoWindow: InfoWindow(
        title: center['name'] as String,
        snippet:
            '${center['region']} • ${center['services'][0]} • Security: $securityLevel',
      ),
      onTap: () {
        setState(() {
          _selectedCenter = center;
        });
      },
      icon: BitmapDescriptor.defaultMarkerWithHue(_securityHue(securityLevel)),
    );
  }).toSet();

  double _securityHue(String securityLevel) {
    switch (securityLevel) {
      case 'Red':
        return BitmapDescriptor.hueRed;
      case 'Blue':
        return BitmapDescriptor.hueAzure;
      default:
        return BitmapDescriptor.hueGreen;
    }
  }

  Color _securityColor(String securityLevel) {
    switch (securityLevel) {
      case 'Red':
        return NavJeevanColors.primaryRose;
      case 'Blue':
        return Colors.blue;
      default:
        return NavJeevanColors.successGreen;
    }
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void _focusCenter() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _center, zoom: 12.5),
      ),
    );
  }

  void _focusNgo(Map<String, dynamic> center) {
    setState(() {
      _selectedCenter = center;
    });
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: center['position'] as LatLng, zoom: 14.5),
      ),
    );
  }

  Future<void> _callCenter(Map<String, dynamic> center) async {
    final String contactNumber = (center['contact'] as String? ?? '').trim();
    if (contactNumber.isEmpty) {
      if (mounted) {
        showErrorBottomPopup(context, 'Contact number is unavailable.');
      }
      return;
    }

    try {
      await FirebaseService.instance.logNgoContactCall(
        ngoId: (center['ngoId'] as String? ?? 'unknown').trim(),
        ngoName: (center['name'] as String? ?? 'Unknown NGO').trim(),
        contact: contactNumber,
        source: 'mother_ngo_map_call',
      );
    } catch (_) {
      // Logging should not block dialing.
    }
    final String sanitized = contactNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri uri = Uri(scheme: 'tel', path: sanitized);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    if (!mounted) {
      return;
    }
    showErrorBottomPopup(context, 'Unable to open dialer on this device.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          _supportsNativeMap
              ? GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 12.0,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: _markers,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  buildingsEnabled: true,
                  trafficEnabled: false,
                )
              : Container(
                  color: NavJeevanColors.petalLight,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Google Maps is available on Android, iOS, and Web builds.\nRun the app on an emulator/device to view live Pune NGO locations.',
                    textAlign: TextAlign.center,
                    style: NavJeevanTextStyles.bodyLarge,
                  ),
                ),

          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildCircleButton(
                    Icons.arrow_back,
                    () => context.go(NavJeevanRoutes.motherHelpRequest),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Support Centers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  _buildCircleButton(
                    Icons.person_outline,
                    () => context.push(NavJeevanRoutes.motherProfile),
                  ),
                ],
              ),
            ),
          ),

          // Map Controls
          Positioned(
            right: 16,
            top: 160,
            child: Column(
              children: [
                _buildMapControl(Icons.my_location, _focusCenter),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMapControlButton(Icons.add, true, _zoomIn),
                      _buildMapControlButton(Icons.remove, false, _zoomOut),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 16,
            right: 90,
            top: 160,
            child: _buildSecurityLegend(),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.26,
            minChildSize: 0.14,
            maxChildSize: 0.68,
            snap: true,
            snapSizes: const [0.14, 0.26, 0.5, 0.68],
            builder: (context, scrollController) {
              return _buildDraggableSheet(scrollController);
            },
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Icon(icon, color: NavJeevanColors.textDark),
      ),
    );
  }

  Widget _buildMapControl(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Icon(icon, color: NavJeevanColors.textDark),
      ),
    );
  }

  Widget _buildMapControlButton(IconData icon, bool top, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          border: top
              ? Border(bottom: BorderSide(color: Colors.grey.shade200))
              : null,
        ),
        child: Icon(icon, color: NavJeevanColors.textDark),
      ),
    );
  }

  Widget _buildDraggableSheet(ScrollController scrollController) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Row(
              children: [
                Text(
                  'FOUND ${_centers.length} CENTERS NEARBY',
                  style: NavJeevanTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedCenter != null) _buildSelectedCenterDetails(),
          ..._centers.map((center) => _buildNgoItem(center)),
        ],
      ),
    );
  }

  Widget _buildSecurityLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: const [
          _LegendItem(
            label: 'Red: High Alert',
            color: NavJeevanColors.primaryRose,
          ),
          _LegendItem(label: 'Blue: Moderate', color: Colors.blue),
          _LegendItem(
            label: 'Green: Safe',
            color: NavJeevanColors.successGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCenterDetails() {
    final center = _selectedCenter!;
    final String securityLevel = center['securityLevel'] as String;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: NavJeevanColors.petalLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NavJeevanColors.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    center['name'] as String,
                    style: NavJeevanTextStyles.titleLarge.copyWith(
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _securityColor(
                      securityLevel,
                    ).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Security: $securityLevel',
                    style: NavJeevanTextStyles.bodySmall.copyWith(
                      color: _securityColor(securityLevel),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Contact: ${center['contact']}',
              style: NavJeevanTextStyles.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Availability: ${center['availability']}',
              style: NavJeevanTextStyles.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Emergency Support: ${center['emergencySupport']}',
              style: NavJeevanTextStyles.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Women Helpline: ${center['womenHelpline']} • Preferred: ${center['preferredContact']}',
              style: NavJeevanTextStyles.bodySmall,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => _callCenter(center),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: NavJeevanColors.primaryRose,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.call, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Call Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNgoItem(Map<String, dynamic> center) {
    final String securityLevel = center['securityLevel'] as String;
    final bool isSelected =
        (_selectedCenter?['ngoId'] as String?) == (center['ngoId'] as String);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _focusNgo(center),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? _securityColor(securityLevel)
                  : NavJeevanColors.borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: NavJeevanColors.petalLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: NavJeevanColors.primaryRose,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      center['name'],
                      style: NavJeevanTextStyles.titleLarge.copyWith(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: NavJeevanColors.textSoft,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          center['region'],
                          style: NavJeevanTextStyles.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '•',
                          style: TextStyle(color: NavJeevanColors.textSoft),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '★ ${center['rating']}',
                          style: NavJeevanTextStyles.bodySmall.copyWith(
                            color: NavJeevanColors.successGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (center['services'] as List<dynamic>).join(' • '),
                      style: NavJeevanTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: _securityColor(
                        securityLevel,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        securityLevel,
                        style: NavJeevanTextStyles.bodySmall.copyWith(
                          color: _securityColor(securityLevel),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _callCenter(center),
                    child: Container(
                      height: 36,
                      width: 36,
                      decoration: const BoxDecoration(
                        color: NavJeevanColors.primaryRose,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.call,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
        currentIndex: 1,
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

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: NavJeevanTextStyles.bodySmall),
      ],
    );
  }
}
