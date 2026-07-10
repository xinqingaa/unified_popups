/// Stable identity for the root route that owned a popup request.
final class PopupRouteToken {
  const PopupRouteToken.internal(this.id);

  final int id;

  @override
  String toString() => 'PopupRouteToken($id)';
}
