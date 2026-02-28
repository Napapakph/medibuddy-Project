import 'package:flutter/foundation.dart';

/// Global guard to prevent auth/session redirects from overriding the
/// alarm screen when the app is opened via a notification tap (cold start).
///
/// Lifecycle: SET → ACTIVE → CLEARED → HANDLE DEFERRED SESSION
class NotificationLaunchGuard {
  /// True while the notification-triggered alarm flow is active.
  static bool isHandlingNotificationOpen = false;

  /// Set to true ONLY when user explicitly presses TAKE/SKIP/SNOOZE.
  static bool userInitiatedAction = false;

  /// If a session-expired event fires during the alarm flow,
  /// we defer the redirect here instead of navigating immediately.
  static bool pendingSessionRedirect = false;

  /// Dedupe: primary key (messageId or fallback composite).
  static String? lastNotiKey;

  /// Dedupe: timestamp of the last processed notification tap.
  static int lastTimestamp = 0;

  /// Profile ID active before the notification opened the alarm screen.
  /// Stored as int? to avoid type-cast errors when navigating back to /home.
  static int? lastActiveProfileIdBeforeOpen;

  // ---------------------------------------------------------------------------
  // Lifecycle helpers
  // ---------------------------------------------------------------------------

  /// SET — called when a notification tap is detected and we are about to
  /// navigate to /alarm.
  static void activate({
    required String notiKey,
    int? profileId,
  }) {
    isHandlingNotificationOpen = true;
    userInitiatedAction = false;
    pendingSessionRedirect = false;
    lastNotiKey = notiKey;
    lastTimestamp = DateTime.now().millisecondsSinceEpoch;
    lastActiveProfileIdBeforeOpen = profileId;
    debugPrint('🔔 [Guard SET] isHandlingNotificationOpen=true '
        'notiKey=$notiKey profileId=$profileId');
  }

  /// Mark that the user explicitly pressed TAKE / SKIP / SNOOZE.
  static void markUserAction() {
    userInitiatedAction = true;
    debugPrint('🔔 [Guard] userInitiatedAction=true');
  }

  /// CLEARED — called only after user-initiated flow finishes and the
  /// navigation to /home completes.
  /// Returns true if there was a deferred session redirect to handle.
  static bool clearAndCheckDeferred() {
    debugPrint('🔔 [Guard CLEARED] isHandlingNotificationOpen → false');
    isHandlingNotificationOpen = false;
    userInitiatedAction = false;
    lastActiveProfileIdBeforeOpen = null;

    if (pendingSessionRedirect) {
      pendingSessionRedirect = false;
      debugPrint('🔔 [Guard DEFERRED SESSION TRIGGERED]');
      return true; // caller should trigger session-expired redirect
    }
    return false;
  }

  /// Check whether an incoming notification tap is a duplicate.
  /// Returns true if this event should be IGNORED.
  static bool isDuplicate(String key) {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Only ignore if BOTH key matches AND within 5-second window.
    if (key == lastNotiKey && (now - lastTimestamp) < 5000) {
      debugPrint('🔔 [Guard] Deduplicated notification tap key=$key');
      return true;
    }
    return false;
  }

  /// Whether the given route is part of the alarm flow.
  static bool isAlarmFlowRoute(String? routeName) {
    return routeName == '/alarm' || routeName == '/confirm_action';
  }
}
