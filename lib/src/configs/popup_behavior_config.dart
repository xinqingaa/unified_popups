import 'popup_back_policy.dart';
import 'popup_conflict_policy.dart';
import 'popup_route_policy.dart';

/// 横切行为设置：身份标识、堆叠、路由与返回键规则。
final class PopupBehaviorConfig {
  /// 使用给定策略创建行为配置。
  const PopupBehaviorConfig({
    this.key,
    this.tags = const <String>{},
    this.conflictPolicy = PopupConflictPolicy.stack,
    this.routePolicy = PopupRoutePolicy.persist,
    this.backPolicy = PopupBackPolicy.dismiss,
  });

  final String? key;
  final Set<String> tags;
  final PopupConflictPolicy conflictPolicy;
  final PopupRoutePolicy routePolicy;
  final PopupBackPolicy backPolicy;

  /// 返回一个选择性覆盖了指定字段的副本。
  ///
  /// 传入 [clearKey] 可移除 [key]；不能与非空的 [key] 同时使用。
  PopupBehaviorConfig copyWith({
    String? key,
    bool clearKey = false,
    Set<String>? tags,
    PopupConflictPolicy? conflictPolicy,
    PopupRoutePolicy? routePolicy,
    PopupBackPolicy? backPolicy,
  }) {
    if (clearKey && key != null) {
      throw ArgumentError('key and clearKey cannot be used together.');
    }
    return PopupBehaviorConfig(
      key: clearKey ? null : key ?? this.key,
      tags: tags ?? this.tags,
      conflictPolicy: conflictPolicy ?? this.conflictPolicy,
      routePolicy: routePolicy ?? this.routePolicy,
      backPolicy: backPolicy ?? this.backPolicy,
    );
  }
}
