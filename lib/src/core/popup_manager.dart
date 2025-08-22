// lib/src/core/popup_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';

part '../models/popup_config.dart';
part '../models/popup_enums.dart';
part '../widgets/popup_layout.dart';

/// 一个用于管理 OverlayEntry 的辅助类，存储每个弹窗的独立状态。
class _PopupInfo {
  final OverlayEntry entry;
  final AnimationController controller;
  final VoidCallback? onDismissCallback;
  Timer? dismissTimer;

  _PopupInfo({
    required this.entry,
    required this.controller,
    this.onDismissCallback,
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

    // 2. 创建 OverlayEntry
    // 注意 onDismiss 回调现在调用 hide(popupId)
    final overlayEntry = OverlayEntry(
      builder: (context) {
        return _PopupLayout(
          config: config,
          animation: animationController.drive(
            CurveTween(curve: Curves.easeInOut),
          ),
          onDismiss: () => hide(popupId),
        );
      },
    );

    // 3. 创建并存储独立的弹窗信息
    final popupInfo = _PopupInfo(
      entry: overlayEntry,
      controller: animationController,
      onDismissCallback: config.onDismiss,
    );
    _instance._popups[popupId] = popupInfo;
    _instance._popupOrder.add(popupId);

    // 4. 插入并播放动画
    overlay.insert(overlayEntry);
    animationController.forward().whenComplete(() {
      config.onShow?.call();
      // 如果设置了 duration，则启动倒计时关闭
      if (config.duration != null) {
        popupInfo.dismissTimer = Timer(config.duration!, () => hide(popupId));
      }
    });

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

  /// 检查指定ID的弹窗是否仍然可见
  static bool isVisible(String popupId) {
    return _instance._popups.containsKey(popupId);
  }
}
