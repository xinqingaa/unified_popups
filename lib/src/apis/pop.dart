// lib/src/apis/pop.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../core/popup_manager.dart';
import '../utils/sheet_dimension.dart';
import '../widgets/confirm_widget.dart';
import '../widgets/date_picker_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/sheet_widget.dart';
import '../widgets/toast_widget.dart';

part 'toast.dart';
part 'loading.dart';
part 'confirm.dart';
part 'sheet.dart';
part 'date.dart';

/// 简洁、易用弹窗API的静态工具类。
abstract class Pop {
  /// 显示一个 Toast 消息
  ///
  /// [message] 消息内容
  /// [position] 显示位置，默认居中
  /// [duration] 显示时长，默认 1.2 秒
  /// [showBarrier] 是否展示蒙层，默认不显示
  /// [barrierDismissible] 点击蒙层是否关闭，默认关闭
  /// [padding], [margin], [decoration], [style], [textAlign] 用于自定义 Toast 样式
  static void toast(
    String message, {
    PopupPosition position = PopupPosition.center,
    Duration duration = const Duration(milliseconds: 1200),
    bool showBarrier = false,
    bool barrierDismissible = false,
    ToastType toastType = ToastType.none,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Decoration? decoration,
    TextStyle? style,
    TextAlign? textAlign,
  }) =>
      _toastImpl(
        message,
        position: position,
        duration: duration,
        showBarrier: showBarrier,
        barrierDismissible: barrierDismissible,
        toastType: toastType,
        padding: padding,
        margin: margin,
        decoration: decoration,
        style: style,
        textAlign: textAlign,
      );

  /// 显示一个 Loading 加载指示器
  ///
  /// [message] 加载时显示的文本，可选
  ///
  /// returns [String] 弹窗的唯一 ID，用于手动关闭
  static String loading({
    String? message,
    Color? backgroundColor,
    double? borderRadius,
    Color? indicatorColor,
    double? indicatorStrokeWidth,
    TextStyle? textStyle,
    bool showBarrier = true,
    bool barrierDismissible = false,
    Color barrierColor = Colors.black54,
  }) =>
      _loadingImpl(
        message: message,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        indicatorColor: indicatorColor,
        indicatorStrokeWidth: indicatorStrokeWidth,
        textStyle: textStyle,
        showBarrier: showBarrier,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
      );

  /// 隐藏 Loading
  ///
  /// [id] showLoading 返回的 ID
  static void hideLoading(String id) => _hideLoadingImpl(id);

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
  static Future<bool?> confirm({
    String? title,
    required String content,
    PopupPosition position = PopupPosition.center,
    String confirmText = 'confirm',
    String? cancelText = 'cancel',
    bool showCloseButton = true,
    TextStyle? titleStyle,
    TextStyle? contentStyle,
    TextStyle? confirmStyle,
    TextStyle? cancelStyle,
    String? imagePath,
    double? imageHeight = 80,
    double? imageWidth,
    TextAlign? textAlign = TextAlign.center,
    ConfirmButtonLayout? buttonLayout = ConfirmButtonLayout.row,
    BorderRadiusGeometry? buttonBorderRadius,
    Color? confirmBgColor,
    Color? cancelBgColor,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Decoration? decoration,
  }) =>
      _confirmImpl(
        title: title,
        content: content,
        position: position,
        confirmText: confirmText,
        cancelText: cancelText,
        imagePath: imagePath,
        imageHeight: imageHeight,
        imageWidth: imageWidth,
        textAlign: textAlign,
        buttonLayout: buttonLayout,
        buttonBorderRadius: buttonBorderRadius,
        showCloseButton: showCloseButton,
        titleStyle: titleStyle,
        contentStyle: contentStyle,
        confirmStyle: confirmStyle,
        cancelStyle: cancelStyle,
        confirmBgColor: confirmBgColor,
        cancelBgColor: cancelBgColor,
        padding: padding,
        margin: margin,
        decoration: decoration,
      );

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
  static Future<T?> sheet<T>({
    required Widget Function(void Function([T? result]) dismiss) childBuilder,
    String? title,
    SheetDirection direction = SheetDirection.bottom,
    bool showCloseButton = false,
    bool? useSafeArea,
    SheetDimension? width,
    SheetDimension? height,
    SheetDimension? maxWidth,
    SheetDimension? maxHeight,
    String? imgPath,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? titlePadding,
    TextStyle? titleStyle,
    TextAlign? titleAlign,
  }) =>
      _sheetImpl<T>(
        childBuilder: childBuilder,
        title: title,
        direction: direction,
        imgPath: imgPath,
        showCloseButton: showCloseButton,
        useSafeArea: useSafeArea,
        width: width,
        height: height,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
        padding: padding,
        titlePadding: titlePadding,
        titleStyle: titleStyle,
        titleAlign: titleAlign,
      );


  /// 显示一个日期选择弹窗
  ///
  /// [initialDate] 初始选中的日期，默认为当前时间
  /// [minDate] 最小可选日期，默认为 1960-01-01
  /// [maxDate] 最大可选日期，默认为当前时间
  /// [title] 弹窗标题，默认为 'Date of Birth'
  /// [position] 弹窗位置，默认为 PopupPosition.bottom
  /// [confirmText] 确认按钮文字
  /// [cancelText] 取消按钮文字
  ///
  /// 返回一个 Future<DateTime?>，如果用户点击确认，则返回选择的日期；
  /// 如果点击取消或遮罩，则返回 null。
  static Future<DateTime?> date({
    DateTime? initialDate,
    DateTime? minDate,
    DateTime? maxDate,
    String title = 'Date of Birth',
    PopupPosition position = PopupPosition.bottom,
    String confirmText = 'Confirm',
    String? cancelText = 'Cancel',
    Color? activeColor = Colors.black,
    Color? noActiveColor = Colors.black38,
    Color? headerBg = Colors.grey,
    double? height = 180.0
  }) =>
      _dateImpl(
        initialDate: initialDate,
        minDate: minDate,
        maxDate: maxDate,
        title: title,
        position: position,
        confirmText: confirmText,
        cancelText: cancelText,
        activeColor: activeColor,
        noActiveColor: noActiveColor,
        height: height,
        headerBg: headerBg
      );

}
