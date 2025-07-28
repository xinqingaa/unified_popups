// lib/src/apis/popup_apis.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../core/popup_manager.dart';
import '../widgets/toast_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/confirm_widget.dart';

/// 提供一组预设好的、易于使用的弹窗 API
class UnifiedPopups {
  /// 显示一个 Toast 消息
  ///
  /// [message] 消息内容
  /// [position] 显示位置，默认底部
  /// [duration] 显示时长，默认 2 秒
  static void showToast(
      String message, {
        PopupPosition position = PopupPosition.bottom,
        Duration duration = const Duration(seconds: 2),
      }) {
    PopupManager.show(
      PopupConfig(
        // 使用预设的 Toast Widget
        child: ToastWidget(message: message),
        position: position,
        // Toast 通常不需要遮盖层
        showBarrier: false,
        // Toast 动画可以根据位置调整
        animation: position == PopupPosition.top
            ? PopupAnimation.slideDown
            : PopupAnimation.slideUp,
        duration: duration,
        // Toast 不需要手动关闭，所以 barrierDismissible 无所谓
        barrierDismissible: false,
      ),
    );
  }

  /// 显示一个 Loading 加载指示器
  ///
  /// [message] 加载时显示的文本，可选
  /// returns [String] 弹窗的唯一 ID，用于手动关闭
  static String showLoading({String? message}) {
    return PopupManager.show(
      PopupConfig(
        child: LoadingWidget(message: message),
        position: PopupPosition.center,
        // Loading 时通常需要遮盖层且不能点击关闭
        showBarrier: true,
        barrierDismissible: false,
        // Loading 通常需要手动关闭，所以 duration 为 null
        duration: null,
      ),
    );
  }

  /// 隐藏 Loading
  ///
  /// [id] showLoading 返回的 ID
  static void hideLoading(String id) {
    PopupManager.hide(id);
  }

  /// 显示一个确认对话框
  ///
  /// [title] 标题
  /// [content] 内容
  /// [confirmText] 确认按钮文本
  /// [cancelText] 取消按钮文本
  /// returns [Future<bool?>] 用户点击确认返回 true，点击取消返回 false，点击遮罩层关闭返回 null
  static Future<bool?> showConfirm({
    required String title,
    String? content,
    String confirmText = '确认',
    String cancelText = '取消',
  }) {
    final completer = Completer<bool?>();
    late String popupId;

    void dismiss(bool? result) {
      if (!completer.isCompleted) {
        completer.complete(result);
        PopupManager.hide(popupId);
      }
    }

    popupId = PopupManager.show(
      PopupConfig(
        child: ConfirmWidget(
          title: title,
          content: content,
          confirmText: confirmText,
          cancelText: cancelText,
          onConfirm: () => dismiss(true),
          onCancel: () => dismiss(false),
        ),
        position: PopupPosition.center,
        barrierDismissible: true,
        onDismiss: () {
          // 如果是通过点击遮罩层关闭的，也需要 complete
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      ),
    );

    return completer.future;
  }

// 你还可以继续添加 showAlert, showBottomSheet 等...
}
