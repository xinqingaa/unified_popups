import 'dart:async';

import '../configs/popup_channel.dart';
import '../configs/toast_config.dart';
import '../configs/toast_lane_motion.dart';
import '../controller/popup_controller.dart';
import '../controller/popup_dismiss_reason.dart';
import '../controller/popup_entry_snapshot.dart';
import '../controller/popup_entry_state.dart';
import '../configs/popup_position.dart';

/// 每个位置只留一条无遮罩 Toast，排队的下一条按 [ToastLaneMotion] 换入同一槽。
///
/// 调度挂在 [PopupController] 上。打开 Toast 的那次调用不能自己保管计时器，
/// 否则下一次调用看不到上一条的停留时间。
final class ToastLaneScheduler {
  ToastLaneScheduler._(this.controller) {
    controller.addListener(_onChange);
  }

  static final Map<PopupController, ToastLaneScheduler> _cache =
      <PopupController, ToastLaneScheduler>{};

  /// 返回 [controller] 上唯一的调度器，并开始监听 Entry 变化。
  static ToastLaneScheduler forController(PopupController controller) {
    return _cache.putIfAbsent(
      controller,
      () => ToastLaneScheduler._(controller),
    );
  }

  /// 取消计时器并解除监听。重复调用没有效果。
  static void detach(PopupController controller) {
    _cache.remove(controller)?.dispose();
  }

  final PopupController controller;

  final Map<String, Timer> _dwellTimers = <String, Timer>{};
  final Map<PopupPosition, Timer> _releaseTimers = <PopupPosition, Timer>{};
  final Map<String, int> _generations = <String, int>{};
  final Map<String, PopupDismissReason> _deferredCloses =
      <String, PopupDismissReason>{};
  final Set<String> _dwellReady = <String>{};

  var _disposed = false;
  var _depth = 0;
  var _resync = false;

  /// 新的无遮罩 Toast 是否要排队。
  ///
  /// 当前条已经完整展示满 [ToastLaneMotion.dwell] 时，立刻开始换场。
  /// 同 key 的冲突交给 Controller，这里不占槽、也不换场。
  bool shouldQueue(ToastConfig config) {
    if (_disposed || config.barrier.visible || _keyIsLive(config)) {
      return false;
    }
    final position = config.position;
    if (_releaseTimers.containsKey(position)) return true;
    final holder = _holder(position);
    if (holder == null) return false;
    if (holder.state == PopupEntryState.visible &&
        _dwellReady.contains(holder.id)) {
      _beginHandoff(holder.id);
    }
    return true;
  }

  /// 队列里还有下一条时，拦住过早的 lifetime 关闭，改到停留满后再换场。
  ///
  /// 返回 true 表示这次关闭已经被车道消化，Controller 不要再关一次。
  bool absorbLifetime(String id, PopupDismissReason reason) {
    if (_disposed) return false;
    if (reason != PopupDismissReason.timeout &&
        reason != PopupDismissReason.externalEvent) {
      return false;
    }
    final entry = _find(id);
    if (entry == null || !_isLane(entry)) return false;
    if (entry.state != PopupEntryState.visible) return false;
    if (!_hasQueued(_position(entry))) return false;
    if (_dwellReady.contains(id)) {
      _beginHandoff(id);
      return true;
    }
    _deferredCloses[id] = reason;
    return true;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final timer in _dwellTimers.values) {
      timer.cancel();
    }
    for (final timer in _releaseTimers.values) {
      timer.cancel();
    }
    _dwellTimers.clear();
    _releaseTimers.clear();
    _deferredCloses.clear();
    _dwellReady.clear();
    _generations.clear();
    controller.removeListener(_onChange);
  }

  void _onChange() {
    if (_disposed) return;
    if (controller.isShutdown) {
      dispose();
      return;
    }
    if (_depth > 0) {
      _resync = true;
      return;
    }
    _depth++;
    try {
      do {
        _resync = false;
        _sync();
      } while (_resync && !_disposed);
    } finally {
      _depth--;
    }
  }

  void _sync() {
    final lane = controller.entries.where(_isLane).toList(growable: false);
    final live = <String>{};
    for (final entry in lane) {
      live.add(entry.id);
      if (entry.state == PopupEntryState.visible) {
        _ensureDwell(entry);
      } else {
        _cancelDwell(entry.id);
        _dwellReady.remove(entry.id);
      }
    }
    for (final id in _dwellTimers.keys.toList(growable: false)) {
      if (!live.contains(id)) _cancelDwell(id);
    }
    _dwellReady.removeWhere((id) => !live.contains(id));
    _deferredCloses.removeWhere((id, _) => !live.contains(id));
    _generations.removeWhere((id, _) => !live.contains(id));
    _promoteIdleLanes(lane);
  }

  void _ensureDwell(PopupEntrySnapshot entry) {
    final id = entry.id;
    final previous = _generations[id];
    if (previous != null && previous != entry.generation) {
      _cancelDwell(id);
      _dwellReady.remove(id);
      _deferredCloses.remove(id);
    }
    _generations[id] = entry.generation;
    if (_dwellReady.contains(id) || _dwellTimers.containsKey(id)) return;
    _dwellTimers[id] = Timer(ToastLaneMotion.dwell, () => _onDwell(id));
  }

  void _onDwell(String id) {
    _dwellTimers.remove(id);
    if (_disposed || controller.isShutdown) return;
    final entry = _find(id);
    if (entry == null || entry.state != PopupEntryState.visible) {
      _deferredCloses.remove(id);
      return;
    }
    final position = _position(entry);
    if (_hasQueued(position)) {
      _deferredCloses.remove(id);
      _beginHandoff(id);
      return;
    }
    final deferred = _deferredCloses.remove(id);
    if (deferred != null) {
      controller.dismissEntry(id, reason: deferred);
      return;
    }
    _dwellReady.add(id);
  }

  void _beginHandoff(String id) {
    if (_disposed) return;
    final entry = _find(id);
    if (entry == null || entry.state != PopupEntryState.visible) return;
    final position = _position(entry);
    if (_releaseTimers.containsKey(position)) return;
    _cancelDwell(id);
    _dwellReady.remove(id);
    _deferredCloses.remove(id);
    _scheduleRelease(position);
    controller.dismissEntry(
      id,
      reason: PopupDismissReason.replaced,
      replaceExit: true,
    );
  }

  void _scheduleRelease(PopupPosition position) {
    _releaseTimers[position]?.cancel();
    _releaseTimers[position] = Timer(ToastLaneMotion.enterDelay, () {
      _releaseTimers.remove(position);
      _releaseNext(position);
    });
  }

  void _promoteIdleLanes(List<PopupEntrySnapshot> lane) {
    final positions = <PopupPosition>{};
    for (final entry in lane) {
      if (entry.state == PopupEntryState.queued) {
        positions.add(_position(entry));
      }
    }
    for (final position in positions) {
      if (_holder(position) != null || _releaseTimers.containsKey(position)) {
        continue;
      }
      _releaseNext(position);
    }
  }

  void _releaseNext(PopupPosition position) {
    if (_disposed || controller.isShutdown || _holder(position) != null) {
      return;
    }
    for (final entry in controller.entries) {
      if (!_isLane(entry) || _position(entry) != position) continue;
      if (entry.state != PopupEntryState.queued) continue;
      controller.releaseQueued(entry.id);
      return;
    }
  }

  void _cancelDwell(String id) {
    _dwellTimers.remove(id)?.cancel();
  }

  bool _keyIsLive(ToastConfig config) {
    final key = config.behavior.key;
    if (key == null) return false;
    for (final entry in controller.entries) {
      if (entry.key != key || entry.state == PopupEntryState.disposed) {
        continue;
      }
      return true;
    }
    return false;
  }

  PopupEntrySnapshot? _holder(PopupPosition position) {
    for (final entry in controller.entries) {
      if (!_isLane(entry) || _position(entry) != position) continue;
      switch (entry.state) {
        case PopupEntryState.entering:
        case PopupEntryState.visible:
        case PopupEntryState.pendingHost:
          return entry;
        case PopupEntryState.created:
        case PopupEntryState.queued:
        case PopupEntryState.dismissRequested:
        case PopupEntryState.exiting:
        case PopupEntryState.disposed:
          continue;
      }
    }
    return null;
  }

  bool _hasQueued(PopupPosition position) {
    for (final entry in controller.entries) {
      if (_isLane(entry) &&
          _position(entry) == position &&
          entry.state == PopupEntryState.queued) {
        return true;
      }
    }
    return false;
  }

  PopupEntrySnapshot? _find(String id) {
    for (final entry in controller.entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  bool _isLane(PopupEntrySnapshot entry) {
    final config = entry.config;
    return entry.channel == PopupChannel.toast &&
        config is ToastConfig &&
        !config.barrier.visible;
  }

  PopupPosition _position(PopupEntrySnapshot entry) =>
      (entry.config! as ToastConfig).position;
}
