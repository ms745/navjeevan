import 'package:flutter/material.dart';
import '../theme/parent_colors.dart';

class AgencyNotificationItem {
  final String title;
  final String message;
  final String category;
  final DateTime time;
  bool isRead;

  AgencyNotificationItem({
    required this.title,
    required this.message,
    required this.category,
    required this.time,
    this.isRead = false,
  });
}

class AgencyNotificationCenter extends ChangeNotifier {
  AgencyNotificationCenter._();

  static final AgencyNotificationCenter instance = AgencyNotificationCenter._();

  final List<AgencyNotificationItem> _items = [];
  bool _seeded = false;

  List<AgencyNotificationItem> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((item) => !item.isRead).length;

  void seedInitialIfNeeded() {
    if (_seeded) return;
    _seeded = true;
    _items.addAll([
      AgencyNotificationItem(
        title: 'Pending Requests',
        message: '3 high-risk surrender/adoption requests need review.',
        category: 'Requests',
        time: DateTime.now().subtract(const Duration(minutes: 35)),
      ),
      AgencyNotificationItem(
        title: 'Welfare Follow-up',
        message: 'Welfare monitoring flagged one case for urgent home visit.',
        category: 'Welfare',
        time: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ]);
    notifyListeners();
  }

  void push({
    required String title,
    required String message,
    required String category,
  }) {
    _items.insert(
      0,
      AgencyNotificationItem(
        title: title,
        message: message,
        category: category,
        time: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void markAllRead() {
    for (final item in _items) {
      item.isRead = true;
    }
    notifyListeners();
  }

  void markRead(AgencyNotificationItem item) {
    item.isRead = true;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

Future<void> showAgencyNotificationsSheet(BuildContext context) {
  final center = AgencyNotificationCenter.instance;
  center.seedInitialIfNeeded();

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return AnimatedBuilder(
        animation: center,
        builder: (context, _) {
          final items = center.items;
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: ParentThemeColors.pureWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Agency Notifications',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: center.markAllRead,
                      child: const Text('Mark all read'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Text(
                            'No notifications yet.',
                            style: TextStyle(color: ParentThemeColors.textMid),
                          ),
                        )
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return InkWell(
                              onTap: () => center.markRead(item),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: item.isRead
                                      ? ParentThemeColors.backgroundLight
                                      : ParentThemeColors.skyBlue.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: ParentThemeColors.borderColor.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (!item.isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: ParentThemeColors.primaryBlue,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(item.message),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${item.category} • ${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: ParentThemeColors.textMid,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
