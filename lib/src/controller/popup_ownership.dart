import '../configs/popup_owner_policy.dart';

/// Associates an entry with a route and, optionally, another popup entry.
final class PopupOwnership {
  const PopupOwnership({
    this.routeToken,
    this.parentEntryId,
    this.policy = PopupOwnerPolicy.independent,
  });

  final Object? routeToken;
  final String? parentEntryId;
  final PopupOwnerPolicy policy;
}
