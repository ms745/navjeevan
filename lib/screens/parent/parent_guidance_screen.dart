import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/parent_colors.dart';
import '../../core/constants/dummy_parent_data.dart';
import '../../core/services/firebase_service.dart';

class ParentGuidanceScreen extends StatefulWidget {
  const ParentGuidanceScreen({super.key});

  @override
  State<ParentGuidanceScreen> createState() => _ParentGuidanceScreenState();
}

class _ParentGuidanceScreenState extends State<ParentGuidanceScreen> {
  final Set<String> _bookmarkedResources = {'Legal Requirements'};
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Legal',
    'Preparation',
    'Financial',
    'Support',
    'Parenting',
    'Documents',
  ];

  void _toggleBookmark(String resourceTitle) {
    setState(() {
      if (_bookmarkedResources.contains(resourceTitle)) {
        _bookmarkedResources.remove(resourceTitle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from bookmarks'),
            backgroundColor: ParentThemeColors.textMid,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        _bookmarkedResources.add(resourceTitle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to bookmarks'),
            backgroundColor: ParentThemeColors.successGreen,
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  List<dynamic> _getFilteredResources() {
    final resources = DummyParentData.guidanceResources;
    return resources.where((resource) {
      final matchesCategory =
          _selectedCategory == 'All' || resource.category == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          resource.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          resource.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.instance.watchCurrentParentApplication(),
      builder: (context, snapshot) {
        final currentParent = DummyParentData.getCurrentParent();
        final liveData = snapshot.data?.data() ?? <String, dynamic>{};
        final assignedChild = Map<String, dynamic>.from(
          liveData['assignedChild'] as Map<String, dynamic>? ?? <String, dynamic>{},
        );
        final adoptionStatus = (liveData['adoptionStatus'] ?? '').toString();
        final verificationStage = (liveData['verificationStage'] ?? '').toString();
        final familyName = (liveData['familyName'] ?? '').toString();

        return Scaffold(
      backgroundColor: ParentThemeColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            _buildCategoryFilter(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeroSection(currentParent, assignedChild, familyName),
                    if (assignedChild.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildPersonalizedGuidanceCard(assignedChild),
                    ],
                    const SizedBox(height: 16),
                    _buildQuickStats(adoptionStatus, verificationStage, assignedChild),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Core Resources'),
                    const SizedBox(height: 12),
                    ..._getFilteredResources().map(
                      (resource) =>
                          _buildResourceCard(context, resource: resource),
                    ),
                    if (_getFilteredResources().isEmpty) _buildEmptyState(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Quick Actions'),
                    const SizedBox(height: 12),
                    _buildQuickActionsGrid(context),
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
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: ParentThemeColors.pureWhite,
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search resources...',
          prefixIcon: const Icon(
            Icons.search,
            color: ParentThemeColors.textMid,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: ParentThemeColors.skyBlue.withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      color: ParentThemeColors.pureWhite,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: ParentThemeColors.skyBlue.withValues(alpha: 0.2),
              selectedColor: ParentThemeColors.primaryBlue,
              labelStyle: TextStyle(
                color: isSelected
                    ? ParentThemeColors.pureWhite
                    : ParentThemeColors.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 64, color: ParentThemeColors.textSoft),
            const SizedBox(height: 16),
            Text(
              'No resources found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ParentThemeColors.textMid,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(fontSize: 14, color: ParentThemeColors.textSoft),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        border: Border(
          bottom: BorderSide(color: ParentThemeColors.skyBlue, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ParentThemeColors.skyBlue.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: ParentThemeColors.deepBlue,
              ),
              onPressed: () => context.pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Parent Guidance Hub',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ParentThemeColors.textDark,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: ParentThemeColors.textMid,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(dynamic parent, Map<String, dynamic> assignedChild, String familyName) {
    final childNickname = (assignedChild['nickname'] ?? '').toString();
    final childTag = assignedChild.isEmpty
        ? 'General guidance'
        : 'Personalized for ${childNickname.isNotEmpty ? childNickname : 'your assigned child'}';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ParentThemeColors.skyBlue, ParentThemeColors.accentPink],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.primaryBlue.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Adoption Journey',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: ParentThemeColors.textDark,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comprehensive resources to guide you through every step of the adoption process with NavJeevan. We\'re here for you.',
            style: TextStyle(
              fontSize: 14,
              color: ParentThemeColors.textMid,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            childTag,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ParentThemeColors.deepBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedGuidanceCard(Map<String, dynamic> assignedChild) {
    final nickname      = (assignedChild['nickname']       ?? '–').toString();
    final age           = (assignedChild['age']            ?? '–').toString();
    final gender        = (assignedChild['gender']         ?? '–').toString();
    final healthStatus  = (assignedChild['healthStatus']   ?? '–').toString();
    final bloodGroup    = (assignedChild['bloodGroup']     ?? '–').toString().toUpperCase();
    final complexion    = (assignedChild['complexion']     ?? '–').toString();
    final heightCm      = (assignedChild['heightCm']       ?? '–').toString();
    final weightKg      = (assignedChild['weightKg']       ?? '–').toString();
    final medicalNotes  = (assignedChild['medicalNotes']   ?? '').toString();
    final specialFeatures = (assignedChild['specialFeatures'] ?? '–').toString();
    final photoUrl      = (assignedChild['photoUrl']       ?? '').toString();

    final genderColor = gender.toLowerCase() == 'female'
        ? ParentThemeColors.pinkDark
        : ParentThemeColors.primaryBlue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ParentThemeColors.primaryBlue.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.primaryBlue.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with photo + name
          Row(
            children: [
              // Child photo / avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: genderColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _childAvatarFallback(gender, genderColor),
                        )
                      : _childAvatarFallback(gender, genderColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.child_care_rounded,
                            size: 14, color: genderColor),
                        const SizedBox(width: 4),
                        const Text(
                          'YOUR ASSIGNED CHILD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: ParentThemeColors.textMid,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nickname,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ParentThemeColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$gender • $age',
                      style: TextStyle(
                        fontSize: 13,
                        color: genderColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: ParentThemeColors.borderColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          // Stats grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _childInfoChip(Icons.favorite_rounded, 'Blood', bloodGroup,
                  ParentThemeColors.pinkDark),
              _childInfoChip(Icons.straighten_rounded, 'Height',
                  heightCm != '–' ? '$heightCm cm' : '–',
                  ParentThemeColors.primaryBlue),
              _childInfoChip(Icons.monitor_weight_outlined, 'Weight',
                  weightKg != '–' ? '$weightKg kg' : '–',
                  ParentThemeColors.successGreen),
              _childInfoChip(Icons.palette_outlined, 'Complexion', complexion,
                  ParentThemeColors.warningOrange),
              _childInfoChip(Icons.health_and_safety_outlined, 'Health',
                  healthStatus, ParentThemeColors.infoBlue),
              if (specialFeatures != '–')
                _childInfoChip(Icons.star_rounded, 'Special',
                    specialFeatures, ParentThemeColors.deepBlue),
            ],
          ),
          if (medicalNotes.isNotEmpty) ...[  
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ParentThemeColors.warningOrange.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      ParentThemeColors.warningOrange.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medical_information_outlined,
                      size: 14,
                      color: ParentThemeColors.warningOrange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Medical Notes: $medicalNotes',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ParentThemeColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _childAvatarFallback(String gender, Color color) {
    return Container(
      color: color.withValues(alpha: 0.08),
      child: Icon(
        gender.toLowerCase() == 'female'
            ? Icons.face_retouching_natural_rounded
            : Icons.face_rounded,
        size: 28,
        color: color.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _childInfoChip(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: ParentThemeColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
    String adoptionStatus,
    String verificationStage,
    Map<String, dynamic> assignedChild,
  ) {
    // Derive a meaningful adoption progress label
    String progressLabel;
    Color progressColor;
    if (adoptionStatus == 'Child Assigned') {
      progressLabel = 'Child Placed';
      progressColor = ParentThemeColors.successGreen;
    } else if (adoptionStatus == 'Verified') {
      progressLabel = 'Awaiting Child';
      progressColor = ParentThemeColors.primaryBlue;
    } else if (verificationStage.isNotEmpty &&
        verificationStage != 'Pending') {
      progressLabel = 'Under Review';
      progressColor = ParentThemeColors.warningOrange;
    } else {
      progressLabel = 'Registered';
      progressColor = ParentThemeColors.textMid;
    }

    final childAssigned = assignedChild.isNotEmpty;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Adoption Status',
            value: progressLabel,
            icon: Icons.trending_up,
            color: progressColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'Child',
            value: childAssigned ? 'Assigned ✓' : 'Pending',
            icon: childAssigned
                ? Icons.child_care_rounded
                : Icons.hourglass_empty_rounded,
            color: childAssigned
                ? ParentThemeColors.successGreen
                : ParentThemeColors.pinkDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ParentThemeColors.borderColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ParentThemeColors.textMid,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildResourceCard(BuildContext context, {required dynamic resource}) {
    final iconMap = {
      'gavel': Icons.gavel,
      'home_health': Icons.home_work,
      'account_balance_wallet': Icons.account_balance_wallet,
      'favorite': Icons.favorite,
      'child_care': Icons.child_care,
      'checklist': Icons.checklist,
    };

    final colorMap = {
      'Legal': ParentThemeColors.primaryBlue,
      'Preparation': ParentThemeColors.pinkDark,
      'Financial': ParentThemeColors.successGreen,
      'Support': ParentThemeColors.warningOrange,
      'Parenting': ParentThemeColors.infoBlue,
      'Documents': ParentThemeColors.deepBlue,
    };

    final icon = iconMap[resource.icon] ?? Icons.book;
    final color = colorMap[resource.category] ?? ParentThemeColors.primaryBlue;
    final isBookmarked = _bookmarkedResources.contains(resource.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBookmarked
              ? color.withValues(alpha: 0.3)
              : ParentThemeColors.borderColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening ${resource.title}...'),
                backgroundColor: color,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              resource.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ParentThemeColors.textDark,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: isBookmarked
                                  ? color
                                  : ParentThemeColors.textSoft,
                            ),
                            onPressed: () => _toggleBookmark(resource.title),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resource.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: ParentThemeColors.textMid,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          resource.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
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
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildQuickActionCard(
          context: context,
          title: 'Video Tutorials',
          icon: Icons.play_circle_outline,
          color: ParentThemeColors.primaryBlue,
        ),
        _buildQuickActionCard(
          context: context,
          title: 'Download Forms',
          icon: Icons.download,
          color: ParentThemeColors.successGreen,
        ),
        _buildQuickActionCard(
          context: context,
          title: 'Book Counseling',
          icon: Icons.event_available,
          color: ParentThemeColors.pinkDark,
        ),
        _buildQuickActionCard(
          context: context,
          title: 'FAQs',
          icon: Icons.help_outline,
          color: ParentThemeColors.warningOrange,
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (title == 'FAQs') {
              context.push(NavJeevanRoutes.parentSupport);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening $title...'),
                  backgroundColor: color,
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ParentThemeColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
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
            isActive: true,
            onTap: () {},
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
            icon: Icons.person_outline,
            label: 'Profile',
            isActive: false,
            onTap: () => context.push(NavJeevanRoutes.parentProfile),
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
