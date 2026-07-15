/// 仅用于查询和分组弹窗条目的分类标签。
///
/// Channel 本身从不驱动返回键、路由或动画行为。
final class PopupChannel {
  /// 使用给定的非空 [name] 创建一个 channel。
  const PopupChannel(this.name) : assert(name != '');

  final String name;

  static const toast = PopupChannel('toast');
  static const loading = PopupChannel('loading');
  static const confirm = PopupChannel('confirm');
  static const sheet = PopupChannel('sheet');
  static const flowSheet = PopupChannel('flowSheet');
  static const menu = PopupChannel('menu');
  static const date = PopupChannel('date');
  static const custom = PopupChannel('custom');

  /// 当两个 channel 的 [name] 相同时视为相等。
  @override
  bool operator ==(Object other) => other is PopupChannel && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'PopupChannel($name)';
}
