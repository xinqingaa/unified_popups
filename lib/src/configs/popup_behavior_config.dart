import 'popup_back_policy.dart';
import 'popup_conflict_policy.dart';
import 'popup_route_policy.dart';

final class PopupBehaviorConfig {
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

  PopupBehaviorConfig copyWith({
    String? key,
    Set<String>? tags,
    PopupConflictPolicy? conflictPolicy,
    PopupRoutePolicy? routePolicy,
    PopupBackPolicy? backPolicy,
  }) {
    return PopupBehaviorConfig(
      key: key ?? this.key,
      tags: tags ?? this.tags,
      conflictPolicy: conflictPolicy ?? this.conflictPolicy,
      routePolicy: routePolicy ?? this.routePolicy,
      backPolicy: backPolicy ?? this.backPolicy,
    );
  }
}
