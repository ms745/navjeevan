import 'package:flutter/material.dart';
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
                  value: _selectedScenario,
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
                  value: _selectedTimeframe,
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
    final riskData = _riskData;
    final hotspotA = riskData['hotspots'][0] as double;
    final hotspotB = riskData['hotspots'][1] as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Regional Risk Analysis',
          style: NavJeevanTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAzt4rT4-rvSwIG65ddh8aycaGgR_vzQI9hwPDga6WSxu5iure6wabkquY130vXlk-dtieDPTTE-J2cn2Kn_5ZQmqjRhjdPrYzDy9kwuuDqxsj0FYF7LHV9gPKB_Lm2zMoqEuw_jJIdp0QPjvBxWbv6M5jIGC0G55QA8M1mDv8MqBBPY3AADczFkbBZh_iCLKRYr5Qc0SBa36Y1RtPqE7GLwEdT-1zS_bvejI0uAVTtjlnVFwtse0SyBkWTaSRHXi3FKxRB7Sf6rJZo',
                  ),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Heatmap simulation
                  Positioned(
                    top: 40,
                    left: 100,
                    child: Container(
                      width: 60 * hotspotA,
                      height: 60 * hotspotA,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    right: 80,
                    child: Container(
                      width: 60 * hotspotB,
                      height: 60 * hotspotB,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.35),
                            blurRadius: 30,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: NavJeevanColors.pureWhite.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REGION FOCUS',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: NavJeevanColors.textSoft,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'Pune Metropolitan Area',
                      style: NavJeevanTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
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
