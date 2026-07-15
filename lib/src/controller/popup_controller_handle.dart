import '../configs/popup_channel.dart';
import 'popup_entry_record.dart';
import 'popup_entry_state.dart';
import 'popup_handle.dart';
import 'popup_outcome.dart';

/// Internal handle implementation forwarding all mutations to the controller.
final class ControllerPopupHandle<T, C> implements UpdatablePopupHandle<T, C> {
  const ControllerPopupHandle({
    required PopupEntryRecord<T, C> record,
    required Future<void> Function(T? value) complete,
    required Future<void> Function() dismiss,
    required bool Function(C config) update,
  })  : _record = record,
        _complete = complete,
        _dismiss = dismiss,
        _update = update;

  final PopupEntryRecord<T, C> _record;
  final Future<void> Function(T? value) _complete;
  final Future<void> Function() _dismiss;
  final bool Function(C config) _update;

  @override
  String get id => _record.id;

  @override
  String? get key => _record.key;

  @override
  PopupChannel get channel => _record.channel;

  @override
  bool get isActive => _record.isActive;

  @override
  bool get isMounted => _record.state.isMounted;

  @override
  PopupEntryState get state => _record.state;

  @override
  Future<PopupOutcome<T>> get outcome => _record.outcomeCompleter.future;

  @override
  Future<T?> get result => outcome.then((outcome) => outcome.value);

  @override
  Future<void> get dismissed => _record.dismissed;

  @override
  Future<void> complete([T? result]) => _complete(result);

  @override
  Future<void> dismiss() => _dismiss();

  @override
  bool update(C config) => _update(config);
}
