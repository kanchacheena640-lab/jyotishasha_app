// lib/features/dashboard/dashboard_tab_switcher.dart
//
// Lets a descendant deep inside DashboardPage's current tab (e.g. Home's
// "Your Astrology Profile   View →" CTA) switch DashboardPage's bottom
// navigation to another tab — the exact same in-place tab switch
// BottomNavigationBar's own onTap already performs — instead of pushing
// or replacing the navigation stack with a new route.
//
// This is the single shared switch-tab code path: DashboardPage's
// BottomNavigationBar.onTap and any descendant reading this class both
// call the same underlying method, so the switch logic is never
// duplicated. Kept in its own file (rather than inside dashboard_page.dart)
// so widgets that need it don't have to import DashboardPage itself.
class DashboardTabSwitcher {
  const DashboardTabSwitcher(this._switchTab);

  final void Function(int index) _switchTab;

  /// Bottom navigation tab indices, matching `DashboardPage._pages` order.
  static const int homeTabIndex = 0;
  static const int astrologyTabIndex = 1;
  static const int reportsTabIndex = 2;
  static const int exploreTabIndex = 3;
  static const int accountTabIndex = 4;

  void switchTo(int index) => _switchTab(index);
}
