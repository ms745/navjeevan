import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class AIRiskTab extends StatefulWidget {
  const AIRiskTab({super.key});

  @override
  State<AIRiskTab> createState() => _AIRiskTabState();
}

class _AIRiskTabState extends State<AIRiskTab> {
  String _selectedScenario = 'Baseline';
  String _selectedTimeframe = '30D';
  MapType _mapType = MapType.normal;
  GoogleMapController? _riskMapController;

  final LatLng _puneCenter = const LatLng(18.5204, 73.8567);
  final List<_RegionRiskPoint> _regionRiskPoints = const [
    _RegionRiskPoint(
      name: 'Hadapsar',
      position: LatLng(18.5089, 73.9259),
      riskScore: 78,
      impactedCases: 182,
    ),
    _RegionRiskPoint(
      name: 'Pune Central',
      position: LatLng(18.5204, 73.8567),
      riskScore: 56,
      impactedCases: 149,
    ),
    _RegionRiskPoint(
      name: 'Aundh',
      position: LatLng(18.5580, 73.8075),
      riskScore: 33,
      impactedCases: 74,
    ),
    _RegionRiskPoint(
      name: 'Pimpri',
      position: LatLng(18.6298, 73.7997),
      riskScore: 68,
      impactedCases: 121,
    ),
    _RegionRiskPoint(
      name: 'Viman Nagar',
      position: LatLng(18.5679, 73.9143),
      riskScore: 42,
      impactedCases: 89,
    ),
    _RegionRiskPoint(
      name: 'Hinjewadi',
      position: LatLng(18.5913, 73.7389),
      riskScore: 24,
      impactedCases: 53,
    ),
  ];

  final List<_RiskRecommendation> _recommendations = [
    _RiskRecommendation(
      title: 'Hadapsar Healthcare Buffer',
      description:
          'Predicted 22% spike in respiratory cases. Increase mobile clinic presence by 3 units.',
      priority: 'HIGH PRIORITY',
      icon: Icons.health_and_safety_rounded,
      color: NavJeevanColors.primaryRose,
    ),
    _RiskRecommendation(
      title: 'Pimpri Education Grants',
      description:
          'Digital divide risk detected in Sector 4. Allocate 500 subsidized tablets.',
      priority: 'OPTIMIZATION',
      icon: Icons.school_rounded,
      color: Colors.blue,
    ),
    _RiskRecommendation(
      title: 'Kothrud Water Supply',
      description:
          'Consumption patterns stable. No immediate allocation adjustment required.',
      priority: 'MONITORED',
      icon: Icons.water_drop_rounded,
      color: Colors.grey,
    ),
  ];

  Map<String, dynamic> get _riskData {
    if (_selectedScenario == 'Conservative') {
      return {
        'score': 48,
        'confidence': 88.3,
        'label': 'MODERATE RISK',
        'hotspots': [0.28, 0.21],
      };
    }
    if (_selectedScenario == 'Aggressive') {
      return {
        'score': 79,
        'confidence': 96.1,
        'label': 'HIGH RISK',
        'hotspots': [0.45, 0.38],
      };
    }

    if (_selectedTimeframe == '7D') {
      return {
        'score': 58,
        'confidence': 90.4,
        'label': 'ELEVATED RISK',
        'hotspots': [0.34, 0.26],
      };
    }
    if (_selectedTimeframe == '90D') {
      return {
        'score': 71,
        'confidence': 95.2,
        'label': 'HIGH RISK',
        'hotspots': [0.42, 0.33],
      };
    }

    return {
      'score': 65,
      'confidence': 94.2,
      'label': 'ELEVATED RISK',
      'hotspots': [0.40, 0.35],
    };
  }

  int get _totalRegions => _regionRiskPoints.length;

  int get _lowRiskRegions =>
      _regionRiskPoints.where((point) => point.riskScore < 34).length;

  int get _mediumRiskRegions =>
      _regionRiskPoints.where((point) => point.riskScore >= 34 && point.riskScore < 67).length;

  int get _highRiskRegions =>
      _regionRiskPoints.where((point) => point.riskScore >= 67).length;

  double _riskPercent(int count) => _totalRegions == 0 ? 0 : (count / _totalRegions) * 100;

  Color _riskColor(int score) {
    if (score >= 67) return Colors.red.shade600;
    if (score >= 34) return Colors.orange.shade600;
    return Colors.green.shade600;
  }

  String _riskLabel(int score) {
    if (score >= 67) return 'High';
    if (score >= 34) return 'Medium';
    return 'Low';
  }

  Set<Circle> get _riskCircles {
    return _regionRiskPoints
        .map(
          (point) => Circle(
            circleId: CircleId('risk_${point.name}'),
            center: point.position,
            radius: 1700,
            strokeWidth: 2,
            strokeColor: _riskColor(point.riskScore),
            fillColor: _riskColor(point.riskScore).withValues(alpha: 0.25),
          ),
        )
        .toSet();
  }

  Set<Marker> get _riskMarkers {
    return _regionRiskPoints
        .map(
          (point) => Marker(
            markerId: MarkerId('risk_marker_${point.name}'),
            position: point.position,
            infoWindow: InfoWindow(
              title: '${point.name} • ${_riskLabel(point.riskScore)} Risk',
              snippet:
                  'Risk score: ${point.riskScore}% | Impacted: ${point.impactedCases} cases',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              point.riskScore >= 67
                  ? BitmapDescriptor.hueRed
                  : point.riskScore >= 34
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueGreen,
            ),
          ),
        )
        .toSet();
  }

  Future<void> _focusRiskMap() async {
    final controller = _riskMapController;
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _puneCenter, zoom: 11.3),
      ),
    );
  }

  void _toggleRecommendation(_RiskRecommendation recommendation) {
    setState(() => recommendation.applied = !recommendation.applied);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(),
          _buildMapSection(),
          _buildRiskGauge(),
          _buildRecommendationList(context),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NavJeevanColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: NavJeevanColors.borderColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 18),
              const SizedBox(width: 8),
              Text(
                'Risk Model Controls',
                style: NavJeevanTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedScenario,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Scenario',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Baseline',
                      child: Text('Baseline'),
                    ),
                    DropdownMenuItem(
                      value: 'Conservative',
                      child: Text('Conservative'),
                    ),
                    DropdownMenuItem(
                      value: 'Aggressive',
                      child: Text('Aggressive'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedScenario = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedTimeframe,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Window',
                  ),
                  items: const [
                    DropdownMenuItem(value: '7D', child: Text('Last 7 days')),
                    DropdownMenuItem(value: '30D', child: Text('Last 30 days')),
                    DropdownMenuItem(value: '90D', child: Text('Last 90 days')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTimeframe = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Regional Risk Analysis',
          style: NavJeevanTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _mapTypeChip('Default', MapType.normal),
            _mapTypeChip('Satellite', MapType.satellite),
            _mapTypeChip('Terrain', MapType.terrain),
            _mapTypeChip('Hybrid', MapType.hybrid),
            TextButton.icon(
              onPressed: _focusRiskMap,
              icon: const Icon(Icons.center_focus_strong_rounded, size: 16),
              label: const Text('Reset View'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 260,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: NavJeevanColors.borderColor.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _puneCenter,
                zoom: 11.3,
              ),
              onMapCreated: (controller) => _riskMapController = controller,
              mapType: _mapType,
              markers: _riskMarkers,
              circles: _riskCircles,
              zoomControlsEnabled: true,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              minMaxZoomPreference: const MinMaxZoomPreference(6, 18),
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _riskLegendTile(
                label: 'Low',
                color: Colors.green.shade600,
                count: _lowRiskRegions,
                percent: _riskPercent(_lowRiskRegions),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _riskLegendTile(
                label: 'Medium',
                color: Colors.orange.shade600,
                count: _mediumRiskRegions,
                percent: _riskPercent(_mediumRiskRegions),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _riskLegendTile(
                label: 'High',
                color: Colors.red.shade600,
                count: _highRiskRegions,
                percent: _riskPercent(_highRiskRegions),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mapTypeChip(String label, MapType type) {
    final selected = _mapType == type;
    return InkWell(
      onTap: () => setState(() => _mapType = type),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? NavJeevanColors.primaryRose.withValues(alpha: 0.12)
              : NavJeevanColors.pureWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? NavJeevanColors.primaryRose.withValues(alpha: 0.3)
                : NavJeevanColors.borderColor.withValues(alpha: 0.35),
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

  Widget _riskLegendTile({
    required String label,
    required Color color,
    required int count,
    required double percent,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: NavJeevanColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NavJeevanColors.borderColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: 6),
              Text(
                '$label Risk',
                style: NavJeevanTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$count Regions',
            style: NavJeevanTextStyles.bodySmall.copyWith(
              color: NavJeevanColors.textSoft,
            ),
          ),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: NavJeevanTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskGauge() {
    final riskData = _riskData;
    final score = (riskData['score'] as int).toDouble();
    final confidence = riskData['confidence'] as double;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NavJeevanColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: NavJeevanColors.borderColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Regional Risk',
                style: NavJeevanTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.info_outline_rounded,
                color: NavJeevanColors.textSoft,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 12,
                  backgroundColor: NavJeevanColors.primaryRose.withValues(
                    alpha: 0.05,
                  ),
                  color: NavJeevanColors.primaryRose,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${score.toInt()}',
                    style: NavJeevanTextStyles.headlineLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 48,
                      color: NavJeevanColors.textDark,
                    ),
                  ),
                  Text(
                    '${riskData['label']}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: NavJeevanColors.primaryRose,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Confidence Interval',
                style: NavJeevanTextStyles.bodySmall.copyWith(
                  color: NavJeevanColors.textSoft,
                ),
              ),
              Text(
                '${confidence.toStringAsFixed(1)}%',
                style: NavJeevanTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: confidence / 100,
            minHeight: 6,
            backgroundColor: Colors.blue.shade50,
            color: Colors.blue,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 16),
          Text(
            'Based on real-time neural modeling and demographic shifts.',
            textAlign: TextAlign.center,
            style: NavJeevanTextStyles.bodySmall.copyWith(
              color: NavJeevanColors.textSoft,
              fontStyle: FontStyle.italic,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welfare Allocation Recommendations',
          style: NavJeevanTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._recommendations.asMap().entries.map((entry) {
          final index = entry.key;
          final recommendation = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _recommendations.length - 1 ? 0 : 12,
            ),
            child: _recommendationCard(
              context: context,
              recommendation: recommendation,
            ),
          );
        }),
      ],
    );
  }

  Widget _recommendationCard({
    required BuildContext context,
    required _RiskRecommendation recommendation,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: NavJeevanColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: recommendation.color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: recommendation.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  recommendation.icon,
                  color: recommendation.color,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: recommendation.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  recommendation.priority,
                  style: TextStyle(
                    color: recommendation.color,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation.title,
            style: NavJeevanTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            recommendation.description,
            style: NavJeevanTextStyles.bodySmall.copyWith(
              color: NavJeevanColors.textSoft,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () {
                _toggleRecommendation(recommendation);
                final msg = recommendation.applied
                    ? 'Applied: ${recommendation.title}'
                    : 'Reverted: ${recommendation.title}';
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
              },
              icon: Icon(
                recommendation.applied
                    ? Icons.check_circle_rounded
                    : Icons.playlist_add_check_rounded,
                size: 16,
                color: recommendation.applied
                    ? NavJeevanColors.emerald
                    : recommendation.color,
              ),
              label: Text(
                recommendation.applied ? 'Applied' : 'Apply Recommendation',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: recommendation.applied
                      ? NavJeevanColors.emerald
                      : recommendation.color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionRiskPoint {
  const _RegionRiskPoint({
    required this.name,
    required this.position,
    required this.riskScore,
    required this.impactedCases,
  });

  final String name;
  final LatLng position;
  final int riskScore;
  final int impactedCases;
}

class _RiskRecommendation {
  _RiskRecommendation({
    required this.title,
    required this.description,
    required this.priority,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final String priority;
  final IconData icon;
  final Color color;
  bool applied = false;
}
