import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/parent_colors.dart';
import '../../core/constants/dummy_parent_data.dart';
import '../../core/constants/dummy_agency_data.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/parent_notification_preferences_store.dart';
import '../../providers/auth_provider.dart';

class ParentSupportScreen extends StatefulWidget {
  const ParentSupportScreen({super.key});

  @override
  State<ParentSupportScreen> createState() => _ParentSupportScreenState();
}

class _ParentSupportScreenState extends State<ParentSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _chatController = TextEditingController();
  bool _supportNotificationsEnabled = true;
  final Map<String, bool> _supportNotificationPrefs = {
    'chatResponses': true,
    'sessionUpdates': true,
    'beforeChildRequest': true,
    'afterChildAcceptance': true,
  };

  final String _anonymousAlias =
      'Parent #${(DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';

  final Map<String, List<Map<String, String>>> _groupMessages = {};

  final List<String> _callStages = const [
    'Not Requested',
    'Requested',
    'In Progress',
    'Scheduled',
    'Completed',
  ];

  final Map<String, Map<String, dynamic>> _callRequests = {
    'Counseling Session': {
      'stage': 0,
      'process': [
        'Request submitted',
        'Counselor assigned',
        'Session slot confirmed',
        'Session completed',
      ],
      'executions': <String>['No request submitted yet.'],
    },
    'Legal Consultation': {
      'stage': 0,
      'process': [
        'Request submitted',
        'Legal expert assigned',
        'Consultation slot confirmed',
        'Consultation completed',
      ],
      'executions': <String>['No request submitted yet.'],
    },
    'Medical Guidance': {
      'stage': 0,
      'process': [
        'Request submitted',
        'Medical advisor assigned',
        'Guidance slot confirmed',
        'Guidance completed',
      ],
      'executions': <String>['No request submitted yet.'],
    },
  };

  int _selectedFaqCategory = 0;

  // Track joined groups
  final Set<String> _joinedGroups = {'New Parents Support Circle'};

  // Chat messages
  final List<Map<String, dynamic>> _chatMessages = [
    {
      'text': 'Hello! How can I assist you today?',
      'isUser': false,
      'time': '10:30 AM',
    },
  ];

  final List<String> _faqCategories = [
    'All',
    'Eligibility',
    'Process',
    'Documents',
    'Financial',
    'Support',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSupportNotificationPreferences();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _toggleGroupMembership(String groupName) {
    setState(() {
      if (_joinedGroups.contains(groupName)) {
        _joinedGroups.remove(groupName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Left $groupName'),
            backgroundColor: ParentThemeColors.textMid,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        _joinedGroups.add(groupName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined $groupName'),
            backgroundColor: ParentThemeColors.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _loadSupportNotificationPreferences() async {
    final stored =
        await ParentNotificationPreferencesStore.loadSupportPreferences();
    if (!mounted) return;

    final loadedPrefs = (stored['prefs'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as bool),
    );

    setState(() {
      _supportNotificationsEnabled = stored['enabled'] as bool;
      _supportNotificationPrefs
        ..clear()
        ..addAll(loadedPrefs);
    });
  }

  Future<void> _saveSupportNotificationPreferences() async {
    await ParentNotificationPreferencesStore.saveSupportPreferences(
      enabled: _supportNotificationsEnabled,
      prefs: Map<String, bool>.from(_supportNotificationPrefs),
    );
  }

  void _ensureGroupMessageSeed(String groupName) {
    if (_groupMessages.containsKey(groupName)) {
      return;
    }

    _groupMessages[groupName] = [
      {
        'sender': 'Parent #4821',
        'message':
            'Welcome everyone. Feel free to ask anything about your first adoption journey.',
        'time': '09:10 AM',
      },
      {
        'sender': 'Parent #7734',
        'message':
            'Weekly peer session starts tonight at 7 PM. You can join anonymously.',
        'time': '09:24 AM',
      },
    ];
  }

  void _sendChatMessage(String message) {
    if (message.trim().isEmpty) return;

    setState(() {
      _chatMessages.add({
        'text': message,
        'isUser': true,
        'time': TimeOfDay.now().format(context),
      });
    });
    _chatController.clear();

    // Simulate bot response
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'text':
                'Thank you for your message. Our team will respond shortly.',
            'isUser': false,
            'time': TimeOfDay.now().format(context),
          });
        });
        _sendSupportNotification('chatResponses');
      }
    });
  }

  void _sendSupportNotification(String category) {
    if (!_supportNotificationsEnabled ||
        (_supportNotificationPrefs[category] ?? false) == false) {
      return;
    }

    final notifications = {
      'chatResponses': 'New response received in Support Chat.',
      'sessionUpdates': 'Your support session request has a new status update.',
      'beforeChildRequest':
          'Before requesting for a child, complete pending verification checklist.',
      'afterChildAcceptance':
          'Congratulations. Post-acceptance support and guidance are now active.',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notifications[category] ?? 'You have a new notification.',
        ),
        backgroundColor: ParentThemeColors.infoBlue,
      ),
    );
  }

  void _openSupportNotifications() {
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
                      'Support Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ParentThemeColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _supportNotificationsEnabled,
                      title: const Text('Enable Support Notifications'),
                      subtitle: const Text('Master switch for support alerts'),
                      activeThumbColor: ParentThemeColors.primaryBlue,
                      onChanged: (value) {
                        setState(() => _supportNotificationsEnabled = value);
                        _saveSupportNotificationPreferences();
                        setModalState(() {});
                      },
                    ),
                    const Divider(),
                    ...[
                      ['chatResponses', 'Chat responses'],
                      ['sessionUpdates', 'Sessions and calls'],
                      ['beforeChildRequest', 'Before child request'],
                      ['afterChildAcceptance', 'After child acceptance'],
                    ].map((entry) {
                      final key = entry[0];
                      final label = entry[1];
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _supportNotificationPrefs[key] ?? false,
                        title: Text(label),
                        activeThumbColor: ParentThemeColors.primaryBlue,
                        onChanged: _supportNotificationsEnabled
                            ? (value) {
                                setState(() {
                                  _supportNotificationPrefs[key] = value;
                                });
                                _saveSupportNotificationPreferences();
                                setModalState(() {});
                              }
                            : null,
                      );
                    }),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _sendSupportNotification('beforeChildRequest');
                            },
                            child: const Text('Send Pre-Request Alert'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _sendSupportNotification('afterChildAcceptance');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ParentThemeColors.primaryBlue,
                            ),
                            child: const Text('Send Post-Accept Alert'),
                          ),
                        ),
                      ],
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

  List<Counsellor> _parentRecommendedCounselors() {
    final matchKeywords = [
      'adoption',
      'family',
      'legal',
      'financial',
      'trauma',
    ];

    final ranked = DummyAgencyData.agencyCounsellors.where((c) {
      if (c.status != 'available') return false;
      final specialty = c.specialty.toLowerCase();
      return matchKeywords.any((keyword) => specialty.contains(keyword));
    }).toList();

    ranked.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    return ranked.take(4).toList();
  }

  Future<void> _requestCounselorAssignment(Counsellor counselor) async {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login again to request assignment.'),
        ),
      );
      return;
    }

    try {
      await FirebaseService.instance.assignCounselorToRequest(
        counselorName: counselor.name,
        counselorEmail: counselor.email ?? '',
        requestId: 'parent_support_$userId',
        userId: userId,
        requestType: 'parent',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${counselor.name} assignment requested.'),
          backgroundColor: ParentThemeColors.successGreen,
        ),
      );
      _sendSupportNotification('sessionUpdates');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not request counselor assignment.'),
        ),
      );
    }
  }

  Widget _buildAvailableCounselorsPanel() {
    final counselors = _parentRecommendedCounselors();
    if (counselors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Available Counselors'),
        const SizedBox(height: 10),
        ...counselors.map((counselor) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ParentThemeColors.pureWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ParentThemeColors.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(counselor.image),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        counselor.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ParentThemeColors.textDark,
                        ),
                      ),
                      Text(
                        counselor.specialty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: ParentThemeColors.textMid,
                        ),
                      ),
                      if (counselor.rating != null)
                        Text(
                          '⭐ ${counselor.rating} • ${counselor.yearsExperience ?? 0} yrs',
                          style: const TextStyle(
                            fontSize: 11,
                            color: ParentThemeColors.textMid,
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _requestCounselorAssignment(counselor),
                  child: const Text('Request'),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _requestOrProgressCall(String callType) {
    final callData = _callRequests[callType];
    if (callData == null) return;

    final int currentStage = callData['stage'] as int;
    final int nextStage = currentStage < (_callStages.length - 1)
        ? currentStage + 1
        : currentStage;
    final executions = (callData['executions'] as List<dynamic>).cast<String>();

    String newExecution;
    if (nextStage == 1) {
      newExecution =
          '${TimeOfDay.now().format(context)} - Request created for $callType.';
    } else if (nextStage == 2) {
      newExecution =
          '${TimeOfDay.now().format(context)} - Specialist assigned for $callType.';
    } else if (nextStage == 3) {
      newExecution =
          '${TimeOfDay.now().format(context)} - Slot confirmed for $callType.';
    } else {
      newExecution =
          '${TimeOfDay.now().format(context)} - $callType process already completed.';
    }

    setState(() {
      callData['stage'] = nextStage;
      if (executions.length == 1 && executions.first.contains('No request')) {
        executions.clear();
      }
      executions.insert(0, newExecution);
    });

    _sendSupportNotification('sessionUpdates');
  }

  void _showCallRequestOverview({String? highlightType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: ParentThemeColors.pureWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Call Requests: Status, Process & Executions',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: ParentThemeColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Track Counseling Session, Legal Consultation, and Medical Guidance requests.',
                    style: TextStyle(
                      fontSize: 12,
                      color: ParentThemeColors.textMid,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: _callRequests.entries.map((entry) {
                        final callType = entry.key;
                        final data = entry.value;
                        final stage = data['stage'] as int;
                        final process = (data['process'] as List<dynamic>)
                            .cast<String>();
                        final executions = (data['executions'] as List<dynamic>)
                            .cast<String>();
                        final isHighlighted = callType == highlightType;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ParentThemeColors.backgroundLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isHighlighted
                                  ? ParentThemeColors.primaryBlue
                                  : ParentThemeColors.borderColor,
                              width: isHighlighted ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      callType,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: ParentThemeColors.textDark,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ParentThemeColors.primaryBlue
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _callStages[stage],
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: ParentThemeColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Process',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: ParentThemeColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...List.generate(process.length, (index) {
                                final completed = index < stage;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        completed
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        size: 14,
                                        color: completed
                                            ? ParentThemeColors.successGreen
                                            : ParentThemeColors.textSoft,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          process[index],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: completed
                                                ? ParentThemeColors.textDark
                                                : ParentThemeColors.textMid,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              const Text(
                                'Executions',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: ParentThemeColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...executions
                                  .take(3)
                                  .map(
                                    (execution) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '• $execution',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: ParentThemeColors.textMid,
                                        ),
                                      ),
                                    ),
                                  ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _requestOrProgressCall(callType);
                                    setModalState(() {});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        ParentThemeColors.primaryBlue,
                                  ),
                                  child: Text(
                                    stage == 0
                                        ? 'Request Now'
                                        : stage < 3
                                        ? 'Update Process'
                                        : 'View Latest Status',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openGroupCommunication(String groupName) {
    _ensureGroupMessageSeed(groupName);
    final TextEditingController groupChatController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final messages = _groupMessages[groupName] ?? [];
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: ParentThemeColors.pureWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$groupName (Anonymous)',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: ParentThemeColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your identity is hidden. You are visible as $_anonymousAlias.',
                    style: TextStyle(
                      fontSize: 12,
                      color: ParentThemeColors.textMid,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: ParentThemeColors.backgroundLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${message['sender']} • ${message['time']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ParentThemeColors.textMid,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message['message'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: ParentThemeColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: groupChatController,
                          decoration: InputDecoration(
                            hintText: 'Share anonymously with group...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          final message = groupChatController.text.trim();
                          if (message.isEmpty) return;
                          setState(() {
                            _groupMessages[groupName] ??= [];
                            _groupMessages[groupName]!.add({
                              'sender': _anonymousAlias,
                              'message': message,
                              'time': TimeOfDay.now().format(context),
                            });
                          });
                          groupChatController.clear();
                          setModalState(() {});
                        },
                        icon: const Icon(
                          Icons.send,
                          color: ParentThemeColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      groupChatController.dispose();
    });
  }

  void _openMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ParentThemeColors.pureWhite,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Share Image'),
                onTap: () {
                  Navigator.pop(context);
                  _sendChatMessage('[Shared image]');
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Share Video'),
                onTap: () {
                  Navigator.pop(context);
                  _sendChatMessage('[Shared video]');
                },
              ),
              ListTile(
                leading: const Icon(Icons.audio_file),
                title: const Text('Share Audio'),
                onTap: () {
                  Navigator.pop(context);
                  _sendChatMessage('[Shared audio file]');
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: const Text('Share Document'),
                onTap: () {
                  Navigator.pop(context);
                  _sendChatMessage('[Shared document]');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _startVoiceChat() {
    _sendChatMessage('[Voice note sent - 00:12]');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice chat note sent.'),
        backgroundColor: ParentThemeColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentThemeColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSupportCallsTab(),
                  _buildSupportGroupsTab(),
                  _buildFAQsTab(),
                  _buildChatbotTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
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
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: ParentThemeColors.textDark,
            ),
            onPressed: () => context.pop(),
          ),
          const Text(
            'Support Center',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ParentThemeColors.textDark,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: ParentThemeColors.textDark,
            ),
            onPressed: _openSupportNotifications,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: ParentThemeColors.pureWhite,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: ParentThemeColors.skyBlue.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            gradient: ParentThemeColors.trustGradient,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: ParentThemeColors.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          dividerColor: Colors.transparent,
          labelColor: ParentThemeColors.pureWhite,
          unselectedLabelColor: ParentThemeColors.textMid,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'Calls', height: 44),
            Tab(text: 'Groups', height: 44),
            Tab(text: 'FAQs', height: 44),
            Tab(text: 'Chat', height: 44),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCallsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmergencyCard(),
          const SizedBox(height: 16),
          _buildAvailableCounselorsPanel(),
          const SizedBox(height: 8),
          _buildSectionTitle('Scheduled Counseling Calls'),
          const SizedBox(height: 12),
          _buildCallCard(
            title: 'Adoption Counselor - Ms. Priya Sharma',
            date: 'March 12, 2026',
            time: '3:00 PM - 4:00 PM',
            status: 'Upcoming',
            statusColor: ParentThemeColors.successGreen,
            icon: Icons.video_call,
          ),
          _buildCallCard(
            title: 'Legal Advisor - Mr. Rajesh Kumar',
            date: 'March 15, 2026',
            time: '11:00 AM - 12:00 PM',
            status: 'Scheduled',
            statusColor: ParentThemeColors.infoBlue,
            icon: Icons.gavel,
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Request a Call'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCallRequestOverview(),
              icon: const Icon(Icons.list_alt),
              label: const Text('View Calls Status / Process / Executions'),
            ),
          ),
          const SizedBox(height: 10),
          _buildRequestCallButtons(),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Emergency Hotline'),
              content: const Text(
                'Call 1800-XXX-XXXX for 24/7 emergency support.\n\nWould you like to make the call now?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Calling emergency hotline...'),
                        backgroundColor: ParentThemeColors.successGreen,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ParentThemeColors.errorRed,
                  ),
                  child: const Text('Call Now'),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ParentThemeColors.errorRed, Color(0xFFFC8181)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ParentThemeColors.errorRed.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ParentThemeColors.pureWhite.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emergency,
                  color: ParentThemeColors.pureWhite,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '24/7 Emergency Hotline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ParentThemeColors.pureWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap to call: 1800-XXX-XXXX',
                      style: TextStyle(
                        fontSize: 14,
                        color: ParentThemeColors.pureWhite,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.phone,
                color: ParentThemeColors.pureWhite,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallCard({
    required String title,
    required String date,
    required String time,
    required String status,
    required Color statusColor,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ParentThemeColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: ParentThemeColors.primaryBlue.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 4),
                    Text(
                      '$date • $time',
                      style: TextStyle(
                        fontSize: 13,
                        color: ParentThemeColors.textMid,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCallButtons() {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.psychology,
          label: 'Counseling Session',
          color: ParentThemeColors.primaryBlue,
          onTap: () =>
              _showCallRequestOverview(highlightType: 'Counseling Session'),
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          icon: Icons.account_balance,
          label: 'Legal Consultation',
          color: ParentThemeColors.successGreen,
          onTap: () =>
              _showCallRequestOverview(highlightType: 'Legal Consultation'),
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          icon: Icons.medical_services,
          label: 'Medical Guidance',
          color: ParentThemeColors.pinkDark,
          onTap: () =>
              _showCallRequestOverview(highlightType: 'Medical Guidance'),
        ),
      ],
    );
  }

  Widget _buildSupportGroupsTab() {
    final groups = DummyParentData.supportGroups;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(
            'Connect with other adoptive parents in your area. Share experiences and support each other.',
            Icons.groups,
          ),
          const SizedBox(height: 16),
          _buildInfoBanner(
            'All group communication is anonymous. No personal identity or credentials are visible.',
            Icons.privacy_tip,
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Active Support Groups'),
          const SizedBox(height: 12),
          ...groups.map((group) => _buildGroupCard(group)),
        ],
      ),
    );
  }

  Widget _buildGroupCard(dynamic group) {
    _ensureGroupMessageSeed(group.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: ParentThemeColors.trustGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.groups,
                  color: ParentThemeColors.pureWhite,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ParentThemeColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: ParentThemeColors.textMid,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.memberCount} members',
                          style: TextStyle(
                            fontSize: 12,
                            color: ParentThemeColors.textMid,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            group.description,
            style: TextStyle(
              fontSize: 13,
              color: ParentThemeColors.textMid,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ParentThemeColors.skyBlue.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  size: 16,
                  color: ParentThemeColors.primaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Next meeting: ${group.nextMeetingDate}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ParentThemeColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _toggleGroupMembership(group.name),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _joinedGroups.contains(group.name)
                        ? ParentThemeColors.textMid
                        : ParentThemeColors.primaryBlue,
                    foregroundColor: ParentThemeColors.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _joinedGroups.contains(group.name)
                        ? 'Leave Group'
                        : 'Join Group',
                  ),
                ),
              ),
              if (_joinedGroups.contains(group.name)) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openGroupCommunication(group.name),
                    icon: const Icon(Icons.forum),
                    label: const Text('Anonymous Chat'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAQsTab() {
    final faqs = DummyParentData.faqs;
    final filteredFaqs = _selectedFaqCategory == 0
        ? faqs
        : faqs
              .where(
                (faq) => faq.category == _faqCategories[_selectedFaqCategory],
              )
              .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: ParentThemeColors.pureWhite,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_faqCategories.length, (index) {
                final isSelected = _selectedFaqCategory == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_faqCategories[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFaqCategory = index;
                      });
                    },
                    backgroundColor: ParentThemeColors.skyBlue.withValues(
                      alpha: 0.3,
                    ),
                    selectedColor: ParentThemeColors.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? ParentThemeColors.pureWhite
                          : ParentThemeColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredFaqs.length,
            itemBuilder: (context, index) {
              return _buildFAQCard(filteredFaqs[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFAQCard(dynamic faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ParentThemeColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.help_outline,
              color: ParentThemeColors.primaryBlue,
              size: 20,
            ),
          ),
          title: Text(
            faq.question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: ParentThemeColors.textDark,
            ),
          ),
          children: [
            const Divider(),
            const SizedBox(height: 8),
            Text(
              faq.answer,
              style: TextStyle(
                fontSize: 14,
                color: ParentThemeColors.textMid,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatbotTab() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ..._chatMessages.map(
                (message) => _buildChatMessage(
                  message['text'] as String,
                  isBot: !(message['isUser'] as bool),
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickReplies(),
            ],
          ),
        ),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildChatMessage(String message, {required bool isBot}) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isBot
              ? ParentThemeColors.lightTrustGradient
              : ParentThemeColors.trustGradient,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: isBot
                ? const Radius.circular(4)
                : const Radius.circular(16),
            bottomRight: isBot
                ? const Radius.circular(16)
                : const Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: ParentThemeColors.primaryBlue.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: isBot
                ? ParentThemeColors.textDark
                : ParentThemeColors.pureWhite,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReplies() {
    final replies = [
      'Document requirements',
      'Timeline',
      'Eligibility criteria',
      'Financial assistance',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: replies.map((reply) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _sendChatMessage(reply),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: ParentThemeColors.primaryBlue),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                reply,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ParentThemeColors.primaryBlue,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            children: [
              _buildChatToolButton(
                icon: Icons.add_photo_alternate,
                label: 'Media',
                onTap: _openMediaOptions,
              ),
              const SizedBox(width: 8),
              _buildChatToolButton(
                icon: Icons.mic,
                label: 'Voice',
                onTap: _startVoiceChat,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: ParentThemeColors.borderColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: ParentThemeColors.primaryBlue,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: ParentThemeColors.trustGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ParentThemeColors.primaryBlue.withValues(
                        alpha: 0.3,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: ParentThemeColors.pureWhite,
                  ),
                  onPressed: () {
                    if (_chatController.text.isNotEmpty) {
                      _sendChatMessage(_chatController.text);
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

  Widget _buildChatToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: ParentThemeColors.primaryBlue,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ParentThemeColors.pureWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ParentThemeColors.textDark,
                  ),
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

  Widget _buildInfoBanner(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ParentThemeColors.skyBlue.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ParentThemeColors.primaryBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: ParentThemeColors.primaryBlue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: ParentThemeColors.textMid),
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
            isActive: true,
            onTap: () {},
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
