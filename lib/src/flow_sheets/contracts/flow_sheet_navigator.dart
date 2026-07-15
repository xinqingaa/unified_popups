import '../pages/flow_sheet_page.dart';

/// FlowSheet 内部页面栈的导航 API。
///
/// 调用方以导航动作（[push]、[replace]、[pop]、[closeAll]）而非页面索引来操作栈。
/// 在页面已挂载时，可通过 [FlowSheetPageState.nav] 获取实例。
abstract class FlowSheetNavigator {
  /// 将 [page] 推入栈中，返回的 future 会在该页面被 [pop] 时携带传入的值完成。
  Future<T?> push<T>(FlowSheetPage<T> page);

  /// 用 [page] 替换栈顶页面，返回的 future 会在新页面被弹出时完成。
  ///
  /// 若栈为空，则行为等同于 [push]。
  Future<T?> replace<T>(FlowSheetPage<T> page);

  /// 弹出栈顶页面，并可选地将 [result] 传回推入该页面的调用方。
  ///
  /// 当仅剩根页面时不执行任何操作；如需关闭整个 sheet，请使用 [closeAll]。
  void pop<T>([T? result]);

  /// 完成当前页面对应 [push] 所返回的 future，但不播放返回转场，也不将该页面从栈中移除。
  ///
  /// 适用于结果已交付且 sheet 即将 [closeAll] 的场景，避免内部弹出动画与 sheet 退出动画同时播放。
  void completeCurrent<T>([T? result]);

  /// 关闭整个 FlowSheet，并可选地将 [result] 传给打开该 sheet 的外部调用方。
  void closeAll([Object? result]);

  /// 是否可以进行内部回退导航（即栈深度大于一）。
  bool get canPop;
}
