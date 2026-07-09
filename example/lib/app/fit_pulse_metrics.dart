/// FitPulse 壳层与 dockToEdge 共用的尺寸，避免 NavigationBar 与默认
/// `kBottomNavigationBarHeight` 不一致导致筛选 Sheet 对不齐。
abstract final class FitPulseMetrics {
  /// Material 3 NavigationBar 内容高度（不含系统手势区）。
  static const double navigationBarHeight = 80;

  /// 底部 Sheet dock 时预留给底栏的间距（高度 + 少量空隙）。
  static const double sheetDockEdgeGap = navigationBarHeight + 4;
}
