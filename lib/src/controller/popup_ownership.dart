import '../configs/popup_owner_policy.dart';

/// 将弹窗与路由、可选父 Entry 关联，用于归属与级联关闭。
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
