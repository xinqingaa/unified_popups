// lib/src/apis/popup_apis.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../core/popup_manager.dart';
import '../widgets/sheet_widget.dart';
import '../widgets/toast_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/confirm_widget.dart';


enum SheetDirection { top, bottom, left, right }

/// 提供一组预设好的、易于使用的弹窗 API
class UnifiedPopups {
  /// 显示一个 Toast 消息
  ///
  /// [message] 消息内容
  /// [position] 显示位置，默认底部
  /// [duration] 显示时长，默认 2 秒
  /// [showBarrier] 是否展示蒙层，默认不显示
  /// [barrierDismissible] 点击蒙层是否关闭，默认关闭
  /// [padding], [margin], [decoration], [style], [textAlign] 用于自定义 Toast 样式
  static void showToast(
      String message, {
        // Popup 级别的配置
        PopupPosition position = PopupPosition.bottom,
        Duration duration = const Duration(seconds: 2),
        bool showBarrier = false,
        bool barrierDismissible = false,
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
          padding: padding,
          margin: margin,
          decoration: decoration,
          style: style,
          textAlign: textAlign,
        ),
        position: position,
        duration: duration,
        animation: animation,
        showBarrier: showBarrier,
        barrierDismissible: barrierDismissible,
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
  /// [cancelText] 取消按钮文本, 如果为 null，则只显示确认按钮
  /// [showCloseButton] 是否显示右上角的关闭按钮, 默认为 true
  /// [titleStyle] 标题样式
  /// [contentStyle] 内容样式
  /// [confirmStyle] 确认按钮文本样式
  /// [cancelStyle] 取消按钮文本样式
  /// [confirmBgColor] 确认按钮背景色
  /// [cancelBgColor] 取消按钮背景色
  /// [padding] 内部边距
  /// [margin] 外部边距
  /// [decoration] 容器的装饰（背景、圆角等）
  /// returns [Future<bool?>] 用户点击确认返回 true，点击取消返回 false，点击遮罩层或关闭按钮返回 null

  static Future<bool?> showConfirm({
    String? title,
    required String content,
    String confirmText = '确认',
    String? cancelText = '取消',
    bool showCloseButton = true,
    TextStyle? titleStyle,
    TextStyle? contentStyle,
    TextStyle? confirmStyle,
    TextStyle? cancelStyle,
    Color? confirmBgColor,
    Color? cancelBgColor,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Decoration? decoration,
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
          showCloseButton: showCloseButton,
          onConfirm: () => dismiss(true),
          onCancel: () => dismiss(false),
          onClose: () => dismiss(null), // 关闭按钮的回调
          // --- 传递样式参数 ---
          titleStyle: titleStyle,
          contentStyle: contentStyle,
          confirmStyle: confirmStyle,
          cancelStyle: cancelStyle,
          confirmBgColor: confirmBgColor,
          cancelBgColor: cancelBgColor,
          padding: padding,
          margin: margin,
          decoration: decoration,
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
  /// 显示一个从指定方向滑出的 Sheet 面板
  ///
  /// [context] BuildContext，用于获取屏幕尺寸
  /// [childBuilder] 内容构建器。它接收一个 dismiss 函数，你可以在你的 child widget 中调用它来关闭 sheet 并返回一个可选的结果。
  ///   例如：`onTap: () => dismiss('item1_selected')`
  /// [title] 可选的标题
  /// [direction] Sheet 的滑出方向，默认为底部
  /// [width] Sheet 的宽度。对于左右方向，默认为屏幕宽度的 75%
  /// [height] Sheet 的高度。对于上下方向，此参数通常不设置，由内容自适应
  /// [backgroundColor], [borderRadius], [boxShadow] 等参数用于完全自定义 Sheet 的外观
  ///
  /// returns [Future<T?>] 当 Sheet 关闭时返回。如果通过 dismiss([result]) 关闭，则返回 result；如果点击蒙层关闭，则返回 null。
  static Future<T?> showSheet<T>(
    BuildContext context, {
      required Widget Function(void Function([T? result]) dismiss) childBuilder,
      String? title,
      SheetDirection direction = SheetDirection.bottom,
      // Widget 级别的样式配置
      double? width,
      double? height,
      Color? backgroundColor,
      BorderRadius? borderRadius,
      List<BoxShadow>? boxShadow,
      EdgeInsetsGeometry? padding,
      EdgeInsetsGeometry? titlePadding,
      TextStyle? titleStyle,
      TextAlign? titleAlign,
      double? titleSpacing,
    }) {
    final completer = Completer<T?>();
    late String popupId;

    void dismiss([T? result]) {
      if (!completer.isCompleted) {
        completer.complete(result);
        PopupManager.hide(popupId);
      }
    }

    // 根据方向选择弹窗位置和动画
    PopupPosition position;
    PopupAnimation animation;
    switch (direction) {
      case SheetDirection.top:
        position = PopupPosition.top;
        animation = PopupAnimation.slideDown;
        break;
      case SheetDirection.left:
        position = PopupPosition.left;
        animation = PopupAnimation.slideLeft;
        break;
      case SheetDirection.right:
        position = PopupPosition.right;
        animation = PopupAnimation.slideRight;
        break;
      case SheetDirection.bottom:
      default:
        position = PopupPosition.bottom;
        animation = PopupAnimation.slideUp;
        break;
    }

    // 为左右抽屉设置默认宽度
    double? sheetWidth = width;
    if (sheetWidth == null && (direction == SheetDirection.left || direction == SheetDirection.right)) {
      sheetWidth = MediaQuery.of(context).size.width * 0.7;
    }

    popupId = PopupManager.show(
      PopupConfig(
        child: SheetWidget(
          title: title,
          direction: direction,
          width: sheetWidth,
          height: height,
          backgroundColor: backgroundColor,
          borderRadius: borderRadius,
          boxShadow: boxShadow,
          padding: padding,
          titlePadding: titlePadding,
          titleStyle: titleStyle,
          titleAlign: titleAlign,
          titleSpacing: titleSpacing,
          // 使用 childBuilder 构建子 Widget，并传入 dismiss 函数
          child: childBuilder(dismiss),
        ),
        position: position,
        animation: animation,
        showBarrier: true,
        barrierDismissible: true,
        onDismiss: () {
          // 点击蒙层关闭
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      ),
    );
    return completer.future;
  }



}
