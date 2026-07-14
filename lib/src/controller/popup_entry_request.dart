import '../configs/popup_back_policy.dart';
import '../configs/popup_channel.dart';
import '../configs/popup_conflict_policy.dart';
import '../configs/popup_route_policy.dart';
import 'popup_lifecycle_callbacks.dart';
import 'popup_lifetime.dart';
import 'popup_ownership.dart';

/// Type-independent information used to register a popup with the controller.
///
/// Concrete popup APIs build this request from their own dedicated config.
final class PopupEntryRequest<T, C> {
  const PopupEntryRequest({
    required this.channel,
    required this.config,
    this.key,
    this.tags = const <String>{},
    this.conflictPolicy = PopupConflictPolicy.stack,
    this.routePolicy = PopupRoutePolicy.persist,
    this.backPolicy = PopupBackPolicy.dismiss,
    this.ownership = const PopupOwnership(),
    this.lifetime = const PopupLifetime.manual(),
    this.lifecycle,
    this.updatable = false,
    this.initiallyQueued = false,
    this.onBack,
    this.resolveUpdate,
  });

  final PopupChannel channel;
  final C config;
  final String? key;
  final Set<String> tags;
  final PopupConflictPolicy conflictPolicy;
  final PopupRoutePolicy routePolicy;
  final PopupBackPolicy backPolicy;
  final PopupOwnership ownership;
  final PopupLifetime lifetime;
  final PopupLifecycleCallbacks<T>? lifecycle;
  final bool updatable;
  final bool initiallyQueued;

  /// Used only when [backPolicy] is [PopupBackPolicy.delegate].
  final Future<bool> Function()? onBack;

  /// Extracts lifecycle behavior when [UpdatablePopupHandle.update] receives a
  /// new type-specific config. Key and channel remain immutable.
  final PopupEntryUpdate<T>? Function(C previous, C next)? resolveUpdate;
}

final class PopupEntryUpdate<T> {
  const PopupEntryUpdate({
    this.tags = const <String>{},
    required this.routePolicy,
    required this.backPolicy,
    required this.ownership,
    required this.lifetime,
    required this.lifecycle,
  });

  final Set<String> tags;
  final PopupRoutePolicy routePolicy;
  final PopupBackPolicy backPolicy;
  final PopupOwnership ownership;
  final PopupLifetime lifetime;
  final PopupLifecycleCallbacks<T> lifecycle;
}
