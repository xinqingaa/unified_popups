import 'popup_back_policy.dart';
import 'popup_channel.dart';
import 'popup_conflict_policy.dart';
import 'popup_route_policy.dart';

final class PopupBehaviorConfig {
  const PopupBehaviorConfig({
    required this.channel,
    this.key,
    this.tags = const <String>{},
    this.conflictPolicy = PopupConflictPolicy.stack,
    this.routePolicy = PopupRoutePolicy.persist,
    this.backPolicy = PopupBackPolicy.dismiss,
  });

  final PopupChannel channel;
  final String? key;
  final Set<String> tags;
  final PopupConflictPolicy conflictPolicy;
  final PopupRoutePolicy routePolicy;
  final PopupBackPolicy backPolicy;

  PopupBehaviorConfig copyWith({
    PopupChannel? channel,
    String? key,
    Set<String>? tags,
    PopupConflictPolicy? conflictPolicy,
    PopupRoutePolicy? routePolicy,
    PopupBackPolicy? backPolicy,
  }) {
    return PopupBehaviorConfig(
      channel: channel ?? this.channel,
      key: key ?? this.key,
      tags: tags ?? this.tags,
      conflictPolicy: conflictPolicy ?? this.conflictPolicy,
      routePolicy: routePolicy ?? this.routePolicy,
      backPolicy: backPolicy ?? this.backPolicy,
    );
  }
}
