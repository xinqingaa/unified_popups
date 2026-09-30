import '../../configs/sheet_types.dart';
import '../pages/flow_sheet_page.dart';

/// FlowSheet 内部页面栈的导航 API。
///
/// 调用方以导航动作（[push]、[replace]、[pop]、[closeAll]）而非页面索引来操作栈。
/// 在页面已挂载时，可通过 [FlowSheetPageState.nav] 获取实例。
abstract class FlowSheetNavigator {
  /// 动态更新当前 FlowSheet 的拖拽关闭模式。
  ///
  /// 页面发生 push/pop/replace 后会重新采用新栈顶页面声明的模式。
  void updateDragDismissMode(SheetDragDismissMode mode);

  /// 将 [page] 推入栈中，返回的 future 会在该页面被 [pop] 时携带传入的值完成。
  ///
  /// 同一种类（[FlowSheetPage.id]）栈内只留一页：
  /// - 栈里没有该 `id`：普通入栈；
  /// - 栈顶就是该 `id`：等同 [replace]（卸掉旧页、新 Widget，不闪回上一页）；
  /// - 该 `id` 在下面：只卸那一页，它上面的页原位留下，再把新页压到顶。
  ///
  /// 再进同一类页直接 [push] 即可，不必先 [contains] / [popTo]。
  Future<T?> push<T>(FlowSheetPage<T> page);

  /// 用 [page] 替换栈顶页面，返回的 future 会在新页面被弹出时完成。
  ///
  /// 若栈为空，则行为等同于 [push]。
  Future<T?> replace<T>(FlowSheetPage<T> page);

  /// 弹出栈顶页面，并可选地将 [result] 传回推入该页面的调用方。
  ///
  /// 当仅剩根页面时不执行任何操作；如需关闭整个 sheet，请使用 [closeAll]。
  void pop<T>([T? result]);

  /// 弹出到根页面（交易主页等），保留栈底一页；已在根页时为 no-op。
  ///
  /// 栈顶页面的等待者收到可选的 [result]，其余被弹出页面以 `null` 完成。
  /// 不关闭整个 sheet；如需关 sheet，请使用 [closeAll]。
  ///
  /// 若目标不是根页，请用 [contains] / [popTo]。
  void popToRoot([Object? result]);

  /// 栈内（含当前页）是否存在 [id]。
  ///
  /// [id] 是路由键，不是「有没有上一页」。上一页不一定是目标宿主，不要用
  /// [canPop] 代替本方法。
  ///
  /// 不传 [identity]：按种类查找，只问「这一类页面在不在」。
  /// 传了 [identity]：再按对象键收窄（同 [id] 栈内最多一页）。
  ///
  /// 再进同一类页请用 [push]（库会卸旧页），不要用本方法决定 pop 还是 push。
  bool contains(String id, {String? identity});

  /// 弹出直到 [id]（或 [id] + [identity] 精确定位的那一份）成为栈顶。
  ///
  /// - 没有匹配的页：debug 断言，release 为 no-op。
  /// - 已是栈顶：no-op，不触发 [FlowSheetPageState.onPoppedTo]。
  /// - 被卸掉的页的 push Future 以 `null` 完成；[result] **只**交给目标页
  ///   [FlowSheetPageState.onPoppedTo]，不要用 push Future 接这个包。
  ///
  /// 会卸掉目标**上面**的所有页。再进同一类页并保留上面已压上的页时，用 [push]。
  void popTo(String id, [Object? result, String? identity]);

  /// 完成当前页面对应 [push] 所返回的 future，但不播放返回转场，也不将该页面从栈中移除。
  ///
  /// 适用于结果已交付、整层稍后由调用方 [closeAll] 的场景
  /// （例如子页把结果交给首页，再由首页关 Sheet）。
  void completeCurrent<T>([T? result]);

  /// 交付当前页结果并关闭整张 FlowSheet，不播放内页返回转场。
  ///
  /// **通用场景：**弹层内点击后要进入全屏 / 外部路由，且不再回到本 FlowSheet。
  /// 让页面内容与外层 Sheet 一起退出，避免「内页右滑 + Sheet 下滑」两套关闭动画。
  ///
  /// 选型：
  /// - 回到上一内页 → [pop]
  /// - 子页只交结果、由上一页关整层 → [completeCurrent]，上一页再 [closeAll]
  ///   （成功收口时不要先 [pop]：会水平滑回上一页再下滑，体验错误）
  /// - 当前页直接离开去全屏 / 外部路由 → [completeAndCloseAll]
  /// - 鉴权门槛等要把整栈换成新首页 → [resetTo]
  void completeAndCloseAll<T>([T? result]);

  /// 关闭整个 FlowSheet，并可选地将 [result] 传给打开该 sheet 的外部调用方。
  void closeAll([Object? result]);

  /// 将内部栈重置为单一 [page]。
  ///
  /// **通用场景：**门槛页（含已 push 的生物验证子页）要用新首页替换整栈
  /// （例如进入交易主页）。不要先 [pop] 再 [replace]，也不要只 [replace] 栈顶
  /// （会留下旧门槛页，系统返回会再次露出）。
  ///
  /// - [animate] 为 `false`（默认）：瞬间换根，无水平转场。与 [replace] 换首页一样。
  /// - [animate] 为 `true`：先以右滑入场推入新页，动画结束后卸掉下方旧页。
  ///   新页成为根，[popToRoot] 落到它；不能侧滑回门槛 / 密码页。
  ///   首次 [ensureInitial] / Sheet 打开仍无水平入场。
  Future<T?> resetTo<T>(FlowSheetPage<T> page, {bool animate = false});

  /// 卸掉栈顶「已 [completeCurrent] 但仍压在上面」的页面，不播返回转场。
  ///
  /// 可连卸多层。用于上一页收到子页结果后，先清掉已交付的上层，再对本页
  /// [completeCurrent] / [pop] / [closeAll]。
  void discardCompletedAbove();

  /// 是否可以进行内部回退导航（即栈深度大于一）。
  bool get canPop;
}
