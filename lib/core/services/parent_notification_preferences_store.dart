import 'package:shared_preferences/shared_preferences.dart';

class ParentNotificationPreferencesStore {
  static const String _supportEnabledKey =
      'parent.support.notifications.enabled';
  static const String _supportChatResponsesKey =
      'parent.support.notifications.chatResponses';
  static const String _supportSessionUpdatesKey =
      'parent.support.notifications.sessionUpdates';
  static const String _supportBeforeRequestKey =
      'parent.support.notifications.beforeChildRequest';
  static const String _supportAfterAcceptanceKey =
      'parent.support.notifications.afterChildAcceptance';

  static const String _profileEnabledKey =
      'parent.profile.notifications.enabled';
  static const String _profileRequestKey = 'parent.profile.notifications.request';
  static const String _profileVerificationKey =
      'parent.profile.notifications.verification';
  static const String _profileAcceptanceKey =
      'parent.profile.notifications.acceptance';
  static const String _profileGuidanceKey =
      'parent.profile.notifications.guidance';
  static const String _profileSupportCallsKey =
      'parent.profile.notifications.supportCalls';
  static const String _profileSessionsKey =
      'parent.profile.notifications.sessions';

  static Future<Map<String, dynamic>> loadSupportPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(_supportEnabledKey) ?? true,
      'prefs': {
        'chatResponses': prefs.getBool(_supportChatResponsesKey) ?? true,
        'sessionUpdates': prefs.getBool(_supportSessionUpdatesKey) ?? true,
        'beforeChildRequest': prefs.getBool(_supportBeforeRequestKey) ?? true,
        'afterChildAcceptance':
            prefs.getBool(_supportAfterAcceptanceKey) ?? true,
      },
    };
  }

  static Future<void> saveSupportPreferences({
    required bool enabled,
    required Map<String, bool> prefs,
  }) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.setBool(_supportEnabledKey, enabled);
    await sharedPrefs.setBool(
      _supportChatResponsesKey,
      prefs['chatResponses'] ?? true,
    );
    await sharedPrefs.setBool(
      _supportSessionUpdatesKey,
      prefs['sessionUpdates'] ?? true,
    );
    await sharedPrefs.setBool(
      _supportBeforeRequestKey,
      prefs['beforeChildRequest'] ?? true,
    );
    await sharedPrefs.setBool(
      _supportAfterAcceptanceKey,
      prefs['afterChildAcceptance'] ?? true,
    );
  }

  static Future<Map<String, dynamic>> loadProfilePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(_profileEnabledKey) ?? true,
      'prefs': {
        'request': prefs.getBool(_profileRequestKey) ?? true,
        'verification': prefs.getBool(_profileVerificationKey) ?? true,
        'acceptance': prefs.getBool(_profileAcceptanceKey) ?? true,
        'guidance': prefs.getBool(_profileGuidanceKey) ?? true,
        'supportCalls': prefs.getBool(_profileSupportCallsKey) ?? true,
        'sessions': prefs.getBool(_profileSessionsKey) ?? true,
      },
    };
  }

  static Future<void> saveProfilePreferences({
    required bool enabled,
    required Map<String, bool> prefs,
  }) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.setBool(_profileEnabledKey, enabled);
    await sharedPrefs.setBool(_profileRequestKey, prefs['request'] ?? true);
    await sharedPrefs.setBool(
      _profileVerificationKey,
      prefs['verification'] ?? true,
    );
    await sharedPrefs.setBool(
      _profileAcceptanceKey,
      prefs['acceptance'] ?? true,
    );
    await sharedPrefs.setBool(_profileGuidanceKey, prefs['guidance'] ?? true);
    await sharedPrefs.setBool(
      _profileSupportCallsKey,
      prefs['supportCalls'] ?? true,
    );
    await sharedPrefs.setBool(_profileSessionsKey, prefs['sessions'] ?? true);
  }
}
