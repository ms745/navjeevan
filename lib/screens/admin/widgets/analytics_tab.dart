import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  String _selectedPeriod = '30D';

  final List<_AdminTask> _tasks = [
    _AdminTask(
      name: 'Sharma Family',
      details: 'Baner • 2 hours ago',
      status: 'PENDING',
    ),
    _AdminTask(
      name: 'Deshpande Family',
      details: 'Kothrud • 5 hours ago',
      status: 'VERIFIED',
    ),
    _AdminTask(
      name: 'Kulkarni Family',
      details: 'Wakad • 1 day ago',
      status: 'IN REVIEW',
    ),
  ];

  Map<String, dynamic> get _periodData {
    switch (_selectedPeriod) {
      case '7D':
        return {
          'requests': 312,
          'requestsTrend': '+4%',
          'verified': 201,
          'verifiedTrend': '+2%',
          'placed': 78,
          'placedTrend': '+3%',
          'regionalTotal': 312,
          'bars': [0.42, 0.55, 0.36, 0.6, 0.4, 0.31],
        };
      case '90D':
        return {
          'requests': 3741,
          'requestsTrend': '+19%',
          'verified': 2624,
          'verifiedTrend': '+11%',
          'placed': 1018,
          'placedTrend': '+13%',
          'regionalTotal': 3741,
          'bars': [0.92, 0.85, 0.74, 0.96, 0.78, 0.65],
        };
      default:
        return {
          'requests': 1284,
          'requestsTrend': '+12%',
          'verified': 856,
          'verifiedTrend': '+5%',
          'placed': 342,
          'placedTrend': '+8%',
          'regionalTotal': 1284,
          'bars': [0.85, 0.70, 0.45, 0.90, 0.55, 0.30],
        };
    }
  }

  void _cycleTaskStatus(_AdminTask task) {
    setState(() {
      if (task.status == 'PENDING') {
        task.status = 'IN REVIEW';
      } else if (task.status == 'IN REVIEW') {
        task.status = 'VERIFIED';
      } else {
        task.status = 'PENDING';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final periodData = _periodData;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildStatsGrid(periodData),
          _buildRegionChart(periodData),
          _buildRecentTasks(context),
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
              (constraints.maxWidth - 24) / 2; // Support 2 columns for now
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
            ],
          );
        },
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

  Widget _buildRegionChart(Map<String, dynamic> periodData) {
    return Container(
      margin: const EdgeInsets.all(16),
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
                  'Baner',
                  periodData['bars'][1] as double,
                  NavJeevanColors.primaryRose,
                ),
                _buildBar(
                  'Kothru',
                  periodData['bars'][2] as double,
                  Colors.orange.shade400,
                ),
                _buildBar(
                  'Wakad',
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
        Container(
          width: 32,
          height: 140 * percentage,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: NavJeevanColors.textSoft,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTasks(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  'Recent Verification Tasks',
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
                            children: _tasks
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
          ..._tasks.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;
            return Column(
              children: [
                _buildTaskItem(task: task),
                if (index != _tasks.length - 1) const Divider(height: 1),
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
    return InkWell(
      onTap: () => _cycleTaskStatus(task),
      child: Padding(
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
      ),
    );
  }

  Color _taskStatusColor(String status) {
    switch (status) {
      case 'VERIFIED':
        return NavJeevanColors.emerald;
      case 'IN REVIEW':
        return Colors.blue;
      default:
        return Colors.amber;
    }
  }
}

class _AdminTask {
  _AdminTask({required this.name, required this.details, required this.status});

  final String name;
  final String details;
  String status;
}
