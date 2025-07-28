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
  /// [padding], [margin], [decoration], [style], [textAlign] 用于自定义 Toast 样式
  static void showToast(
      String message, {
        // Popup 级别的配置
        PopupPosition position = PopupPosition.bottom,
        Duration duration = const Duration(seconds: 2),
        // Widget 级别的样式配置
        EdgeInsetsGeometry? padding,
        EdgeInsetsGeometry? margin,
        Decoration? decoration,
        TextStyle? style,
        TextAlign? textAlign,
      }) {
    // 根据位置决定一个更合适的默认动画
    final animation = (position == PopupPosition.top)
        ? PopupAnimation.slideDown
        : (position == PopupPosition.bottom)
        ? PopupAnimation.slideUp
        : PopupAnimation.fade;

    PopupManager.show(
      PopupConfig(
        child: ToastWidget(
          message: message,
          // 将所有样式参数原封不动地传递给 Widget
          padding: padding,
          margin: margin,
          decoration: decoration,
          style: style,
          textAlign: textAlign,
        ),
        position: position,
        duration: duration,
        animation: animation,
        // Toast 的合理默认行为
        showBarrier: false,
        barrierDismissible: false,
      ),
    );
  }

  /// 显示一个 Loading 加载指示器
  ///
  /// [message] 加载时显示的文本，可选
  /// returns [String] 弹窗的唯一 ID，用于手动关闭
  static String showLoading({
    String? message,
    // 样式参数
    Color? backgroundColor,
    double? borderRadius,
    Color? indicatorColor,
    double? indicatorStrokeWidth,
    TextStyle? textStyle,
    // 遮罩层参数
    bool barrierDismissible = false,
    Color barrierColor = Colors.black54,
  }) {
    return PopupManager.show(
      PopupConfig(
        child: LoadingWidget(
          message: message,
          backgroundColor: backgroundColor,
          borderRadius: borderRadius,
          indicatorColor: indicatorColor,
          indicatorStrokeWidth: indicatorStrokeWidth,
          textStyle: textStyle,
        ),
        position: PopupPosition.center,
        showBarrier: true,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
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
