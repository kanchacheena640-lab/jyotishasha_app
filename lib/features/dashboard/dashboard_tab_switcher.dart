// lib/features/dashboard/dashboard_tab_switcher.dart
//
// Lets a descendant deep inside DashboardPage's current tab switch
// DashboardPage's bottom navigation to another in-place tab — the exact
// same switch BottomNavigationBar's own onTap performs for the tabs that
// are still real, in-place _pages entries — instead of pushing or
// replacing the navigation stack with a new route.
//
// This is the single shared switch-tab code path: DashboardPage's
// BottomNavigationBar.onTap (via _switchTab) and any descendant reading
// this class both call the same underlying method, so the switch logic
// is never duplicated. Kept in its own file (rather than inside
// dashboard_page.dart) so widgets that need it don't have to import
// DashboardPage itself.
//
// Task 4 — `astrologyTabIndex` was removed: Astrology no longer occupies
// a bottom-nav slot (replaced by Ask Now, which is always a pushed
// route, never an in-place tab — see dashboard_page.dart's
// _onBottomNavTap), and the only descendant that used to read it
// (GreetingHeaderWidget's "Your Astrology Profile" CTA) now pushes
// KundaliOverviewPage directly instead. The remaining indices are
// unchanged and still genuinely correspond to real, in-place _pages
// entries.
class DashboardTabSwitcher {
  const DashboardTabSwitcher(this._switchTab);

  final void Function(int index) _switchTab;

  /// Bottom navigation tab indices, matching `DashboardPage._pages` order.
  static const int homeTabIndex = 0;
  static const int reportsTabIndex = 2;
  static const int exploreTabIndex = 3;
  static const int accountTabIndex = 4;

  void switchTo(int index) => _switchTab(index);
}
