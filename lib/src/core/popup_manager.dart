// lib/src/core/popup_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

part '../models/popup_config.dart';
part '../models/popup_enums.dart';
part '../widgets/popup_layout.dart';

// https://docs.flutter.dev/development/tools/sdk/release-notes/release-notes-3.0.0
T? _ambiguate<T>(T? value) => value;

/// 安全的 OverlayEntry，避免在构建阶段调用 setState 导致的错误。
/// 
/// 重写 markNeedsBuild() 方法，检查当前是否在构建阶段。
/// 如果在构建阶段（SchedulerPhase.persistentCallbacks），则延迟到 postFrameCallback 执行。
class SafeOverlayEntry extends OverlayEntry {
  SafeOverlayEntry({
    required super.builder,
    super.opaque,
    super.maintainState,
  });

  @override
  void markNeedsBuild() {
    if (_ambiguate(SchedulerBinding.instance)!.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      _ambiguate(SchedulerBinding.instance)!.addPostFrameCallback((_) {
        super.markNeedsBuild();
      });
    } else {
      super.markNeedsBuild();
    }
  }
}

/// 一个用于管理 OverlayEntry 的辅助类，存储每个弹窗的独立状态。
class _PopupInfo {
  final OverlayEntry entry;
  final AnimationController controller;
  final VoidCallback? onDismissCallback;
  final PopupType type;
  Timer? dismissTimer;

  _PopupInfo({
    required this.entry,
    required this.controller,
    this.onDismissCallback,
    this.type = PopupType.other,
  });
}

/// 统一弹窗管理器，支持同时显示多个、互不干扰的弹窗。
class PopupManager {
  PopupManager._();

  static final PopupManager _instance = PopupManager._();

  /// 获取单例实例
  static PopupManager get instance => _instance;

  static GlobalKey<NavigatorState>? _navigatorKey;

  /// 存储所有当前活跃的弹窗信息
  /// 使用 Map 来通过唯一 ID 管理每个弹窗
  final Map<String, _PopupInfo> _popups = {};

  /// 按显示顺序记录弹窗ID，方便实现 hideLast()
  final List<String> _popupOrder = [];

  /// 创建一个 ValueNotifier 来广播非 Toast 弹窗的状态。
  static final ValueNotifier<bool> hasNonToastPopupNotifier = ValueNotifier(false);

  static GlobalKey<NavigatorState> get navigatorKey {
    if (_navigatorKey == null) {
      throw StateError(
          'PopupManager has not been initialized. Please call PopupManager.initialize() in your main function.');
    }
    return _navigatorKey!;
  }

  /// 初始化管理器，必须在 MaterialApp 中设置 navigatorKey
  static void initialize({required GlobalKey<NavigatorState> navigatorKey}) {
    _navigatorKey = navigatorKey;
  }

  /// 私有辅助方法，用于在状态改变时更新 Notifier。
  static void _updateNotifier() {
    // 只有当值确实发生变化时，ValueNotifier 才会通知其监听者，性能开销极小。
    hasNonToastPopupNotifier.value = hasNonToastPopup;
    // debugPrint('[PopupManager] Notifier: $hasNonToastPopup');
  }

  /// 私有方法：执行实际的插入和动画操作
  /// 
  /// 将 overlay.insert() 和动画启动逻辑提取到独立方法，
  /// 以便在构建阶段时可以延迟执行。
  static void _insertPopup(
    OverlayState overlay,
    OverlayEntry overlayEntry,
    AnimationController animationController,
    PopupConfig config,
    String popupId,
    _PopupInfo popupInfo,
  ) {
    overlay.insert(overlayEntry);
    animationController.forward().whenComplete(() {
      config.onShow?.call();
      // 如果设置了 duration，则启动倒计时关闭
      if (config.duration != null) {
        popupInfo.dismissTimer = Timer(config.duration!, () => hide(popupId));
      }
    });
  }

  /// 显示弹出层，并返回一个唯一的 ID 用于后续控制。
  ///
  /// [config] 弹出层的详细配置
  /// returns [String] 弹窗的唯一 ID
  static String show(PopupConfig config) {
    if (_navigatorKey?.currentState?.overlay == null) {
      throw Exception(
          'PopupManager not initialized. Please call PopupManager.initialize() in your main function.');
    }

    final overlay = _navigatorKey!.currentState!.overlay!;
    final popupId =
        'popup_${DateTime.now().microsecondsSinceEpoch}_${_instance._popups.length}';

    // 1. 为新弹窗创建独立的 AnimationController
    final animationController = AnimationController(
      vsync: overlay,
      duration: config.animationDuration,
    );

    // 2. 创建 SafeOverlayEntry（避免在构建阶段调用 setState 导致的错误）
    // 注意 onDismiss 回调现在调用 hide(popupId)
    final overlayEntry = SafeOverlayEntry(
      builder: (context) {
        return RepaintBoundary(
          child: _PopupLayout(
            config: config,
            animation: animationController.drive(
              CurveTween(curve: Curves.easeInOut),
            ),
            onDismiss: () => hide(popupId),
          ),
        );
      },
    );

    // 3. 创建并存储独立的弹窗信息
    final popupInfo = _PopupInfo(
      entry: overlayEntry,
      controller: animationController,
      onDismissCallback: config.onDismiss,
      type: config.type,
    );
    _instance._popups[popupId] = popupInfo;
    _instance._popupOrder.add(popupId);

    _updateNotifier();

    // 4. 检查构建阶段，如果在构建阶段则延迟执行插入操作
    // 这避免了在路由构建过程中（如 Get.put() 立即初始化 Controller）调用时触发 setState 错误
    final schedulerPhase = _ambiguate(SchedulerBinding.instance)?.schedulerPhase;
    if (schedulerPhase == SchedulerPhase.persistentCallbacks) {
      // 在构建阶段，延迟到下一帧执行
      _ambiguate(SchedulerBinding.instance)!.addPostFrameCallback((_) {
        _insertPopup(overlay, overlayEntry, animationController, config, popupId, popupInfo);
      });
    } else {
      // 不在构建阶段，立即执行
      _insertPopup(overlay, overlayEntry, animationController, config, popupId, popupInfo);
    }

    return popupId;
  }

  /// 根据 ID 隐藏指定的弹出层
  static void hide(String popupId) {
    final popupInfo = _instance._popups[popupId];
    if (popupInfo == null) {
      // 可能已经被关闭，直接返回
      return;
    }

    // 从管理器中立即移除，防止重复关闭
    _instance._popups.remove(popupId);
    _instance._popupOrder.remove(popupId);

    _updateNotifier();

    // 取消可能存在的倒计时
    popupInfo.dismissTimer?.cancel();

    // 播放退出动画，动画结束后清理资源
    popupInfo.controller.reverse().whenComplete(() {
      // 检查 entry 是否还在 tree 中，避免重复移除导致的错误
      if (popupInfo.entry.mounted) {
        popupInfo.entry.remove();
      }
      popupInfo.controller.dispose();

      // 调用保存的回调
      popupInfo.onDismissCallback?.call();
    });
  }

  /// 隐藏最新显示的弹出层
  static void hideLast() {
    if (_instance._popupOrder.isNotEmpty) {
      final lastId = _instance._popupOrder.last;
      hide(lastId);
    }
  }

  /// 隐藏所有当前显示的弹出层
  static void hideAll() {
    // 创建一个key的副本进行迭代，因为 hide() 方法会修改 _popups Map
    final allPopupIds = List<String>.from(_instance._popups.keys);
    for (final id in allPopupIds) {
      hide(id);
    }
  }

  /// 根据类型隐藏指定类型的弹出层
  /// 
  /// 从最新的弹窗开始查找，找到第一个匹配类型的弹窗并关闭。
  /// 主要用于 loading 等单一实例的弹窗类型。
  /// 
  /// [type] 要关闭的弹窗类型
  /// 返回 true 如果找到并关闭了弹窗，否则返回 false
  static bool hideByType(PopupType type) {
    // 从最新的弹窗开始查找（倒序）
    for (int i = _instance._popupOrder.length - 1; i >= 0; i--) {
      final id = _instance._popupOrder[i];
      final info = _instance._popups[id];
      if (info != null && info.type == type) {
        hide(id);
        return true;
      }
    }
    return false;
  }

  /// 检查指定ID的弹窗是否仍然可见
  static bool isVisible(String popupId) {
    return _instance._popups.containsKey(popupId);
  }

  /// 是否存在非 Toast 的弹窗
  static bool get hasNonToastPopup {
    for (final id in _instance._popupOrder) {
      final info = _instance._popups[id];
      if (info != null && info.type != PopupType.toast) return true;
    }
    return false;
  }

  /// 关闭最新的非 Toast 弹窗。成功关闭返回 true
  static bool hideLastNonToast() {
    // debugPrint('[PopupManager] hideLastNonToast.');
    for (int i = _instance._popupOrder.length - 1; i >= 0; i--) {
      final id = _instance._popupOrder[i];
      final info = _instance._popups[id];
      if (info != null && info.type != PopupType.toast) {
        hide(id);
        // debugPrint('[PopupManager] Found and hid a non-toast popup.');
        return true;
      }
    }
    // debugPrint('[PopupManager] No non-toast popup found to hide.');
    return false;
  }

  /// 智能返回方法
  ///
  /// 如果有弹窗（非Toast），则关闭最上层的弹窗。
  /// 否则，执行标准的 Navigator.pop()。
  /// 这对于自定义返回按钮非常有用。
  static void maybePop(BuildContext context) {
    if (hideLastNonToast()) {
      // 如果成功关闭了一个弹窗，则什么都不做
      return;
    } else {
      // 否则，如果 context 仍然有效，则返回上一页
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }
}