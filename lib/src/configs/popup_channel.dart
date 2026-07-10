/// A query-only category for grouping popup entries.
///
/// A channel never drives back, route, or animation behavior.
final class PopupChannel {
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

  @override
  bool operator ==(Object other) => other is PopupChannel && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'PopupChannel($name)';
}
