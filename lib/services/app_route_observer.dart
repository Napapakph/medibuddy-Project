import 'package:flutter/widgets.dart';

/// A custom [NavigatorObserver] that tracks the current route name.
///
/// This is the single source of truth for knowing which named route
/// is currently displayed.  Register it on [MaterialApp.navigatorObservers].
class AppRouteObserver extends NavigatorObserver {
  /// The publicly readable current route name.
  static String? currentRouteName;

  // ---------------------------------------------------------------------------
  // NavigatorObserver overrides
  // ---------------------------------------------------------------------------

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _update(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _update(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _update(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _update(previousRoute);
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _update(Route<dynamic>? route) {
    final name = route?.settings.name;
    currentRouteName = name;
    debugPrint('📍 [AppRouteObserver] currentRouteName → $name');
  }
}
