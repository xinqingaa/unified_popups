import '../pages/flow_sheet_page.dart';

/// FlowSheet 内部页面栈的导航接口。
///
/// 调用方不关心 page index，只用导航动作：[push]、[replace]、[pop]、[closeAll]。
abstract class FlowSheetNavigator {
  /// 推入一个新页面，返回该页面 [pop] 时回传的结果。
  Future<T?> push<T>(FlowSheetPage<T> page);

  /// 用新页面替换栈顶页面。
  Future<T?> replace<T>(FlowSheetPage<T> page);

  /// 返回上一页，可携带结果给发起 [push] 的调用方。
  void pop<T>([T? result]);

  /// 只把结果回传给发起 [push] 的调用方，不触发返回转场，页面停留原地。
  ///
  /// 用于「回传结果后外层会立刻 [closeAll]」的场景，避免内部返回动画与
  /// sheet 整体退场动画并行播放。
  void completeCurrent<T>([T? result]);

  /// 关闭整个 FlowSheet，可携带最终结果给外层调用方。
  void closeAll([Object? result]);

  /// 当前是否存在可返回的内部页面（栈深度 > 1）。
  bool get canPop;
}
