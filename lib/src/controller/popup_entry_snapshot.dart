import '../configs/popup_back_policy.dart';
import '../configs/popup_channel.dart';
import '../configs/popup_route_policy.dart';
import 'popup_entry_state.dart';
import 'popup_ownership.dart';

/// Immutable host-facing view of an entry.
final class PopupEntrySnapshot {
  const PopupEntrySnapshot({
    required this.id,
    required this.key,
    required this.channel,
    required this.state,
    required this.config,
    required this.generation,
    required this.backPolicy,
    required this.routePolicy,
    required this.ownership,
    this.paused = false,
  });

  final String id;
  final String? key;
  final PopupChannel channel;
  final PopupEntryState state;
  final Object? config;
  final int generation;
  final PopupBackPolicy backPolicy;
  final PopupRoutePolicy routePolicy;
  final PopupOwnership ownership;

  /// When true, Host keeps the entry mounted but Offstage / non-interactive.
  final bool paused;
}
