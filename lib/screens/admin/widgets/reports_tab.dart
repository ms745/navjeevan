import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final List<_AdminReportItem> _reports = [
    _AdminReportItem(
      title: 'Annual CARA Activity Report',
      subtitle: 'Full audit of platform verification cycles.',
      lastGenerated: 'Oct 24, 2023',
      fileSize: '4.2 MB',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBLVcUepiTNColpBOZN186MhbU_cgN1_AW8mpMamJZV4D_ePptFvxjOyQ_wnJdfHM29A_2s_AHhaAQ8FZH8QWwLEWKNcrAzjWVzqUOJ2dVVqchHKJjg8qFE-L_PXr1X2dBQdk4iiOqgJivHFIcH1QCqhoG9yzfoFpOKqIhNT6N0cb59TYIegGAd99mgDwmx-PoVF8i6eO_Y5vrAS5u65g5qgA87VG8J2zdC5ZK5UiNvCtU6E3Alf-acZ1k760HlGc6h3Ilu54UD31U_',
      isDownload: true,
    ),
    _AdminReportItem(
      title: 'Monthly Risk Assessment',
      subtitle: 'Detailed AI model risk score breakdown.',
      lastGenerated: 'Oct 1 - Oct 31',
      fileSize: 'Ready to Generate',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCBnQmw3St8WYk4iIuzNP3uoR4ASR1y8uIlmAaH59zqgrbDAUTcP9Lx1MwLppsFW35FqubnnfhuZ-6KfTjU1CbaY04OgYOFYcPi6aNWso-04bPkm8myRox9RnoIyrzmbsfFEzfAGSYhFpaIAIWa3rf3pXYt2jBVhzw98DI-rwUqX7cde-liiOs3pwhQVDix00u0YJsQPPlBZpeQ8nz-A4EfLLan0Db3y76pIiqHyVn3SIhmh028oqY30wYM0fKFHosOOOAqPPdFDi-F',
      isDownload: false,
    ),
  ];

  final List<_DeadlineItem> _deadlines = [
    _DeadlineItem(
      date: 'NOV 15',
      title: 'Quarterly Board Review',
      subtitle: 'Requires AI Risk Summary attachment',
      bgColor: Colors.pink.shade50,
      textColor: Colors.pink.shade700,
    ),
    _DeadlineItem(
      date: 'DEC 01',
      title: 'Annual System Audit',
      subtitle: 'External compliance review starts',
      bgColor: Colors.blue.shade50,
      textColor: Colors.blue.shade700,
    ),
  ];

  Future<void> _handleReportAction(_AdminReportItem report) async {
    if (report.isDownload) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Downloading ${report.title}...')));
      return;
    }

    setState(() => report.isGenerating = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    setState(() {
      report.isGenerating = false;
      report.isDownload = true;
      report.fileSize = '2.6 MB';
      report.lastGenerated = 'Just now';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${report.title} generated successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummarySection(),
          _buildReportsList(context),
          _buildDeadlineSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NavJeevanColors.primaryRose.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: NavJeevanColors.primaryRose.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compliance Overview',
            style: NavJeevanTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: NavJeevanTextStyles.bodySmall.copyWith(
                color: NavJeevanColors.textSoft,
              ),
              children: [
                const TextSpan(text: 'Platform status is currently '),
                TextSpan(
                  text: 'Compliant',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: '. Last audit completed 2 days ago.'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildSummaryBox('VERIFICATIONS', '12,482')),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryBox('RISK ALERTS', '04')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NavJeevanColors.pureWhite.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: NavJeevanColors.textSoft,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: NavJeevanTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Generate Summaries',
              style: NavJeevanTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: NavJeevanColors.primaryRose.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'CARA v2.1',
                style: TextStyle(
                  color: NavJeevanColors.primaryRose,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._reports.asMap().entries.map((entry) {
          final index = entry.key;
          final report = entry.value;
          return Column(
            children: [
              _reportCard(context: context, report: report),
              if (index != _reports.length - 1) const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  Widget _reportCard({
    required BuildContext context,
    required _AdminReportItem report,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: NavJeevanColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 140,
              child: Stack(
                children: [
                  Image.network(
                    report.imageUrl,
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      report.title,
                      style: NavJeevanTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      report.isDownload
                          ? Icons.info_outline_rounded
                          : Icons.security_rounded,
                      color: NavJeevanColors.textSoft,
                      size: 20,
                    ),
                  ],
                ),
                Text(
                  report.subtitle,
                  style: NavJeevanTextStyles.bodySmall.copyWith(
                    color: NavJeevanColors.textSoft,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.isDownload
                              ? 'Last generated: ${report.lastGenerated}'
                              : 'Status: ${report.fileSize}',
                          style: TextStyle(
                            fontSize: 10,
                            color: NavJeevanColors.textSoft,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          report.isDownload
                              ? 'File size: ${report.fileSize}'
                              : 'Covers: ${report.lastGenerated}',
                          style: TextStyle(
                            fontSize: 10,
                            color: NavJeevanColors.textSoft,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: report.isGenerating
                          ? null
                          : () => _handleReportAction(report),
                      icon: Icon(
                        report.isGenerating
                            ? Icons.sync
                            : report.isDownload
                            ? Icons.download_rounded
                            : Icons.refresh_rounded,
                        size: 16,
                      ),
                      label: Text(
                        report.isGenerating
                            ? 'Generating...'
                            : report.isDownload
                            ? 'Download PDF'
                            : 'Generate',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: report.isDownload
                            ? NavJeevanColors.primaryRose
                            : NavJeevanColors.petalLight.withValues(alpha: 0.5),
                        foregroundColor: report.isDownload
                            ? Colors.white
                            : NavJeevanColors.primaryRose,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          'Upcoming Deadlines',
          style: NavJeevanTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._deadlines.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _deadlines.length - 1 ? 0 : 12,
            ),
            child: _deadlineItem(item),
          );
        }),
      ],
    );
  }

  Widget _deadlineItem(_DeadlineItem item) {
    return InkWell(
      onTap: () {
        setState(() => item.completed = !item.completed);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NavJeevanColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.completed
                ? NavJeevanColors.emerald.withValues(alpha: 0.5)
                : NavJeevanColors.borderColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: item.bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    item.date.split(' ')[0],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: item.textColor,
                    ),
                  ),
                  Text(
                    item.date.split(' ')[1],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: item.textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: NavJeevanTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    style: NavJeevanTextStyles.bodySmall.copyWith(
                      color: NavJeevanColors.textSoft,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              item.completed
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: item.completed
                  ? NavJeevanColors.emerald
                  : NavJeevanColors.textSoft,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminReportItem {
  _AdminReportItem({
    required this.title,
    required this.subtitle,
    required this.lastGenerated,
    required this.fileSize,
    required this.imageUrl,
    required this.isDownload,
  });

  final String title;
  final String subtitle;
  String lastGenerated;
  String fileSize;
  final String imageUrl;
  bool isDownload;
  bool isGenerating = false;
}

class _DeadlineItem {
  _DeadlineItem({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.textColor,
  });

  final String date;
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color textColor;
  bool completed = false;
}
