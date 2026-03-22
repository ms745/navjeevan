import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/services/firebase_service.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  String _selectedPeriod = '30D';
  GoogleMapController? _mapController;
  MapType _mapType = MapType.normal;

  // Pune center coordinates
  final LatLng _puneCenter = const LatLng(18.5204, 73.8567);

  final Map<String, LatLng> _regionCoords = {
    'Pune Central': const LatLng(18.5204, 73.8567),
    'Hadapsar': const LatLng(18.5089, 73.9259),
    'Aundh': const LatLng(18.5580, 73.8075),
    'Pimpri': const LatLng(18.6298, 73.7997),
    'Viman Nagar': const LatLng(18.5679, 73.9143),
    'Hinjewadi': const LatLng(18.5913, 73.7389),
    'Wakad': const LatLng(18.5987, 73.7753),
    'Kothrud': const LatLng(18.5074, 73.8077),
    'Baner': const LatLng(18.5590, 73.7797),
  };

  Future<void> _zoomMapBy(double delta) async {
    final controller = _mapController;
    if (controller == null) return;
    final zoom = await controller.getZoomLevel();
    await controller.animateCamera(
      CameraUpdate.zoomTo((zoom + delta).clamp(5.0, 18.0)),
    );
  }

  Future<void> _resetMapView() async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _puneCenter, zoom: 11.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.instance.watchAllRequests(),
      builder: (context, motherSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('adoptive_families').snapshots(),
          builder: (context, familySnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.instance.watchAllCounselingBookings(),
              builder: (context, bookingSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.instance.watchAllCounselingRequests(),
                  builder: (context, requestSnap) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseService.instance.watchAllCounselorAssignments(),
                      builder: (context, assignmentSnap) {
                        final motherDocs = motherSnap.data?.docs ?? [];
                        final familyDocs = familySnap.data?.docs ?? [];
                        final bookingDocs = bookingSnap.data?.docs ?? [];
                        final counselingRequestDocs = requestSnap.data?.docs ?? [];
                        final assignmentDocs = assignmentSnap.data?.docs ?? [];

                        // Process counts
                        final totalRequests = motherDocs.length;
                        final activeRequests = motherDocs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return (data['status'] ?? 'Active') == 'Active';
                        }).length;
                        final inProcessRequests = motherDocs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return (data['status'] ?? '') == 'In Process';
                        }).length;
                        final acceptedRequests = motherDocs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return (data['status'] ?? '') == 'Accepted';
                        }).length;
                        final declinedRequests = motherDocs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return (data['status'] ?? '') == 'Declined';
                        }).length;
                        final verifiedFamilies = familyDocs.where((d) => (d.data() as Map)['adoptionStatus'] == 'Verified').length;
                        final childrenPlaced = familyDocs.where((d) => (d.data() as Map)['adoptionStatus'] == 'Child Assigned').length;
                        final requestedBookings = bookingDocs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return (data['status'] ?? 'Requested') == 'Requested';
                        }).length;
                        final confirmedBookings = bookingDocs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return (data['status'] ?? '') == 'Confirmed';
                        }).length;
                        final quickSupportRequests = counselingRequestDocs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return (data['status'] ?? 'Requested') == 'Requested';
                        }).length;
                        final activeAssignments = assignmentDocs.length;

                        // Regional data for chart
                        final regionsForChart = ['Hadapsar', 'Pune Central', 'Aundh', 'Pimpri', 'Viman Nagar', 'Hinjewadi'];
                        final regionalCounts = {for (var r in regionsForChart) r: 0};
            
                        // Markers setup
                        final Set<Marker> markers = {};
                        final Map<String, int> regionHeat = {};

                        for (var doc in motherDocs) {
                          final reg = (doc.data() as Map)['region'] ?? 'Unknown';
                          if (regionalCounts.containsKey(reg)) {
                            regionalCounts[reg] = regionalCounts[reg]! + 1;
                          }
                          regionHeat[reg] = (regionHeat[reg] ?? 0) + 1;
                        }
            
                        // Create markers based on regional activity
                        regionHeat.forEach((region, countValue) {
                          if (_regionCoords.containsKey(region)) {
                            markers.add(
                              Marker(
                                markerId: MarkerId(region),
                                position: _regionCoords[region]!,
                                infoWindow: InfoWindow(
                                  title: region,
                                  snippet: '$countValue total request(s) in this area',
                                ),
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  countValue > 5 ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
                                ),
                              ),
                            );
                          }
                        });

                        final maxCount = regionalCounts.values.fold(1, (max, val) => val > max ? val : max);
                        final bars = regionsForChart.map((r) => regionalCounts[r]! / maxCount).toList();

                        final liveData = {
                          'requests': totalRequests,
                          'requestsTrend': '+${motherDocs.length % 15}%',
                          'activeRequests': activeRequests,
                          'inProcessRequests': inProcessRequests,
                          'acceptedRequests': acceptedRequests,
                          'declinedRequests': declinedRequests,
                          'verified': verifiedFamilies,
                          'verifiedTrend': '+2%',
                          'placed': childrenPlaced,
                          'placedTrend': '+0%',
                          'regionalTotal': totalRequests,
                          'bars': bars,
                          'markers': markers,
                          'requestedBookings': requestedBookings,
                          'confirmedBookings': confirmedBookings,
                          'quickSupportRequests': quickSupportRequests,
                          'activeAssignments': activeAssignments,
                        };

                        return SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(context),
                              _buildStatsGrid(liveData),
                              _buildRequestLifecycleSection(liveData),
                              _buildCounselingOpsSection(liveData),
                              _buildMapSection(markers),
                              _buildRegionChart(liveData),
                              _buildRecentTasks(context, motherDocs),
                              const SizedBox(height: 24),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await FirebaseService.instance.seedInitialData();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Initial Data Seeded Successfully!')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.auto_awesome),
                                  label: const Text('Seed Initial Data'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: NavJeevanColors.primaryRose,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCounselingOpsSection(Map<String, dynamic> periodData) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NavJeevanColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: NavJeevanColors.borderColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Counselor Operations',
            style: NavJeevanTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Live booking, support queue, and assignment metrics',
            style: NavJeevanTextStyles.bodySmall.copyWith(
              color: NavJeevanColors.textSoft,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _lifecycleChip('Booking Requests', periodData['requestedBookings'], Colors.deepPurple),
              _lifecycleChip('Confirmed Sessions', periodData['confirmedBookings'], Colors.green),
              _lifecycleChip('Quick Support Queue', periodData['quickSupportRequests'], Colors.teal),
              _lifecycleChip('Active Assignments', periodData['activeAssignments'], Colors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pune Admin Analytics',
            style: NavJeevanTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: NavJeevanColors.textDark,
            ),
          ),
          Text(
            'Regional Overview & Metrics',
            style: NavJeevanTextStyles.bodySmall.copyWith(
              color: NavJeevanColors.textSoft,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: ['7D', '30D', '90D'].map((period) {
              final selected = _selectedPeriod == period;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedPeriod = period),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? NavJeevanColors.primaryRose.withValues(alpha: 0.12)
                          : NavJeevanColors.pureWhite,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? NavJeevanColors.primaryRose.withValues(alpha: 0.4)
                            : NavJeevanColors.borderColor.withValues(
                                alpha: 0.3,
                              ),
                      ),
                    ),
                    child: Text(
                      period,
                      style: TextStyle(
                        color: selected
                            ? NavJeevanColors.primaryRose
                            : NavJeevanColors.textSoft,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> periodData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double width =
              (constraints.maxWidth - 24) / 2; // Support 2 columns
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard(
                title: 'Total Requests',
                value: '${periodData['requests']}',
                trend: '${periodData['requestsTrend']}',
                icon: Icons.pending_actions_rounded,
                iconBg: Colors.blue.shade50,
                iconColor: Colors.blue.shade600,
                width: width,
              ),
              _buildStatCard(
                title: 'Verified Families',
                value: '${periodData['verified']}',
                trend: '${periodData['verifiedTrend']}',
                icon: Icons.family_restroom_rounded,
                iconBg: NavJeevanColors.petalLight.withValues(alpha: 0.5),
                iconColor: NavJeevanColors.primaryRose,
                width: width,
              ),
              _buildStatCard(
                title: 'Children Placed',
                value: '${periodData['placed']}',
                trend: '${periodData['placedTrend']}',
                icon: Icons.child_care_rounded,
                iconBg: NavJeevanColors.blush.withValues(alpha: 0.5),
                iconColor: NavJeevanColors.primaryRose,
                width: width,
              ),
              _buildStatCard(
                title: 'Active Cases',
                value: '${periodData['activeRequests']}',
                trend: 'Live',
                icon: Icons.pending_actions_rounded,
                iconBg: Colors.orange.shade50,
                iconColor: Colors.orange.shade700,
                width: width,
              ),
              _buildStatCard(
                title: 'In Process',
                value: '${periodData['inProcessRequests']}',
                trend: 'Live',
                icon: Icons.sync_rounded,
                iconBg: Colors.blue.shade50,
                iconColor: Colors.blue.shade700,
                width: width,
              ),
              _buildStatCard(
                title: 'Accepted',
                value: '${periodData['acceptedRequests']}',
                trend: 'Live',
                icon: Icons.check_circle_rounded,
                iconBg: Colors.green.shade50,
                iconColor: Colors.green.shade700,
                width: width,
              ),
              _buildStatCard(
                title: 'Declined',
                value: '${periodData['declinedRequests']}',
                trend: 'Live',
                icon: Icons.cancel_rounded,
                iconBg: Colors.red.shade50,
                iconColor: Colors.red.shade700,
                width: width,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestLifecycleSection(Map<String, dynamic> periodData) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NavJeevanColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: NavJeevanColors.borderColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mother Request Lifecycle',
            style: NavJeevanTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Real-time operational distribution from Firestore',
            style: NavJeevanTextStyles.bodySmall.copyWith(
              color: NavJeevanColors.textSoft,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _lifecycleChip('Active', periodData['activeRequests'], Colors.orange),
              _lifecycleChip('In Process', periodData['inProcessRequests'], Colors.blue),
              _lifecycleChip('Accepted', periodData['acceptedRequests'], Colors.green),
              _lifecycleChip('Declined', periodData['declinedRequests'], Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lifecycleChip(String label, Object? value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String trend,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NavJeevanColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NavJeevanColors.borderColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: NavJeevanColors.emerald,
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    trend,
                    style: TextStyle(
                      color: NavJeevanColors.emerald,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: NavJeevanTextStyles.bodySmall.copyWith(
              color: NavJeevanColors.textSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: NavJeevanTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(Set<Marker> markers) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NavJeevanColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: NavJeevanColors.borderColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Regional Distribution Map',
            style: NavJeevanTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _mapStyleChip('Default', MapType.normal),
              _mapStyleChip('Satellite', MapType.satellite),
              _mapStyleChip('Terrain', MapType.terrain),
              _mapStyleChip('Hybrid', MapType.hybrid),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: NavJeevanColors.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _puneCenter,
                      zoom: 11.0,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    mapType: _mapType,
                    markers: markers,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    zoomGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    rotateGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    compassEnabled: true,
                    mapToolbarEnabled: false,
                    minMaxZoomPreference: const MinMaxZoomPreference(5.0, 18.0),
                    gestureRecognizers: {
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Column(
                  children: [
                    _mapActionButton(
                      icon: Icons.add,
                      onPressed: () => _zoomMapBy(1),
                    ),
                    const SizedBox(height: 8),
                    _mapActionButton(
                      icon: Icons.remove,
                      onPressed: () => _zoomMapBy(-1),
                    ),
                    const SizedBox(height: 8),
                    _mapActionButton(
                      icon: Icons.center_focus_strong_rounded,
                      onPressed: _resetMapView,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mapStyleChip(String label, MapType type) {
    final selected = _mapType == type;
    return InkWell(
      onTap: () => setState(() => _mapType = type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? NavJeevanColors.primaryRose.withValues(alpha: 0.12)
              : NavJeevanColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? NavJeevanColors.primaryRose.withValues(alpha: 0.35)
                : NavJeevanColors.borderColor.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected
                ? NavJeevanColors.primaryRose
                : NavJeevanColors.textSoft,
          ),
        ),
      ),
    );
  }

  Widget _mapActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: NavJeevanColors.pureWhite.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: NavJeevanColors.borderColor.withValues(alpha: 0.4),
            ),
          ),
          child: Icon(icon, size: 18, color: NavJeevanColors.textDark),
        ),
      ),
    );
  }

  Widget _buildRegionChart(Map<String, dynamic> periodData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NavJeevanColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: NavJeevanColors.borderColor.withValues(alpha: 0.3),
        ),
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
                    'Region-wise Requests',
                    style: NavJeevanTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Activity across Pune districts',
                    style: NavJeevanTextStyles.bodySmall.copyWith(
                      color: NavJeevanColors.textSoft,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: NavJeevanColors.primaryRose.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedPeriod == '7D'
                      ? 'Last 7 Days'
                      : _selectedPeriod == '90D'
                      ? 'Last 90 Days'
                      : 'Last 30 Days',
                  style: TextStyle(
                    color: NavJeevanColors.primaryRose,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '${periodData['regionalTotal']}',
            style: NavJeevanTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total regional submissions',
            style: NavJeevanTextStyles.bodySmall.copyWith(
              color: NavJeevanColors.textSoft,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(
                  'Hadap',
                  periodData['bars'][0] as double,
                  Colors.blue.shade400,
                ),
                _buildBar(
                  'PuneC',
                  periodData['bars'][1] as double,
                  NavJeevanColors.primaryRose,
                ),
                _buildBar(
                  'Aundh',
                  periodData['bars'][2] as double,
                  Colors.orange.shade400,
                ),
                _buildBar(
                  'Pimpr',
                  periodData['bars'][3] as double,
                  Colors.blue.shade400,
                ),
                _buildBar(
                  'Viman',
                  periodData['bars'][4] as double,
                  NavJeevanColors.primaryRose,
                ),
                _buildBar(
                  'Hinje',
                  periodData['bars'][5] as double,
                  Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double percentage, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: 32,
          height: (140 * percentage).clamp(5.0, 140.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.length > 5 ? label.substring(0, 5) : label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: NavJeevanColors.textSoft,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTasks(
    BuildContext context,
    List<QueryDocumentSnapshot> motherDocs,
  ) {
    final recentTasks = motherDocs.take(5).map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final region = (data['region'] ?? 'Unknown').toString();
      final reasons = ((data['reasons'] as List?) ?? const []).join(', ');
      final createdAt = data['createdAt'] as Timestamp?;
      return _AdminTask(
        id: doc.id,
        name: reasons.isEmpty ? 'Mother Request' : reasons,
        details:
            '$region • ${createdAt != null ? _formatDate(createdAt.toDate()) : 'Recently'}',
        status: (data['status'] ?? 'Active').toString(),
      );
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: NavJeevanColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: NavJeevanColors.borderColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Mother Request Tasks',
                  style: NavJeevanTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (sheetContext) {
                        return SafeArea(
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: recentTasks
                                .map(
                                  (task) => ListTile(
                                    title: Text(task.name),
                                    subtitle: Text(task.details),
                                    trailing: Text(
                                      task.status,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _taskStatusColor(task.status),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        );
                      },
                    );
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: NavJeevanColors.primaryRose,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...recentTasks.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;
            return Column(
              children: [
                _buildTaskItem(task: task),
                  if (index != recentTasks.length - 1) const Divider(height: 1),
              ],
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTaskItem({required _AdminTask task}) {
    final statusColor = _taskStatusColor(task.status);
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: NavJeevanTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    task.details,
                    style: NavJeevanTextStyles.bodySmall.copyWith(
                      color: NavJeevanColors.textSoft,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                task.status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
  }

  Color _taskStatusColor(String status) {
    switch (status) {
      case 'Accepted':
        return NavJeevanColors.emerald;
      case 'In Process':
        return Colors.blue;
      case 'Declined':
        return Colors.red;
      default:
        return Colors.amber;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _AdminTask {
  _AdminTask({
    required this.id,
    required this.name,
    required this.details,
    required this.status,
  });

  final String id;
  final String name;
  final String details;
  String status;
}
