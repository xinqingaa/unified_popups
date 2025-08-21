// lib/src/apis/pop.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../core/popup_manager.dart';
import '../utils/sheet_dimension.dart';
import '../widgets/confirm_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/sheet_widget.dart';
import '../widgets/toast_widget.dart';

part 'toast.dart';
part 'loading.dart';
part 'confirm.dart';
part 'sheet.dart';


/// 简洁、易用弹窗API的静态工具类。
abstract class Pop {
  /// 显示一个 Toast 消息
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
  static void hideLoading(String id) => _hideLoadingImpl(id);

  /// 显示一个确认对话框
  static Future<bool?> confirm({
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
  }) =>
      _confirmImpl(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
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
}