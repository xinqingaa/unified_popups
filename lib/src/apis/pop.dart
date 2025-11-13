// lib/src/apis/pop.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../core/popup_manager.dart';
import '../utils/sheet_dimension.dart';
import '../widgets/confirm_widget.dart';
import '../widgets/date_picker_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/menu_widget.dart';
import '../widgets/sheet_widget.dart';
import '../widgets/toast_widget.dart';

part 'toast.dart';
part 'loading.dart';
part 'confirm.dart';
part 'sheet.dart';
part 'date.dart';
part 'menu.dart';

/// 统一、简洁的弹窗 API 静态工具类。
///
/// - 轻提示（`toast`）
/// - 加载中（`loading` / `hideLoading`）
/// - 确认对话框（`confirm`）
/// - 抽屉/底部面板（`sheet<T>`）
/// - 日期选择器（`date`）

abstract class Pop {
  /// 显示一个 Toast 消息。
  ///
  /// 参数：
  /// - [message]：消息文本（必填）。
  /// - [position]：显示位置，默认 `PopupPosition.center`（居中）。
  /// - [duration]：显示时长，默认 `1200ms`。到时自动关闭。
  /// - [showBarrier]：是否显示遮罩层，默认 `false`。通常 toast 不需要遮罩。
  /// - [barrierDismissible]：点击遮罩是否关闭，默认 `false`。
  /// - [toastType]：Toast 等级（success/warn/error/none），默认 `none`。可用于展示不同图标/配色。
  /// - [animationDuration]：动画持续时间，默认 `200ms`。toast 需要快速显示。
  /// - [customImagePath]：自定义图片路径，如果提供则覆盖 toastType 的图标。
  /// - [imageSize]：图片大小，默认 `24.0`。
  /// - [imgColor]：自定义图片的着色（仅在 `customImagePath` 时生效）。
  /// - [layoutDirection]：布局方向，默认 `Axis.horizontal`（Row），`Axis.vertical` 为 Column（图片在上，文字在下）。
  /// - [padding]/[margin]/[decoration]/[style]/[textAlign]：细粒度样式定制。
  ///
  /// 用法示例：
  /// ```dart
  /// Pop.toast('保存成功', toastType: ToastType.success);
  /// Pop.toast('网络异常，请稍后重试', position: PopupPosition.bottom, duration: Duration(seconds: 2));
  /// Pop.toast('自定义图片', customImagePath: 'assets/custom.png', layoutDirection: Axis.vertical);
  /// ```
  static void toast(
    String message, {
    PopupPosition position = PopupPosition.center,
    Duration duration = const Duration(milliseconds: 1200),
    bool showBarrier = false,
    bool barrierDismissible = false,
    ToastType toastType = ToastType.none,
    Duration animationDuration = const Duration(milliseconds: 200),
    String? customImagePath,
    double? imageSize,
    Color? imgColor,
    Axis layoutDirection = Axis.horizontal,
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
        animationDuration: animationDuration,
        customImagePath: customImagePath,
        imageSize: imageSize,
        imgColor: imgColor,
        layoutDirection: layoutDirection,
        padding: padding,
        margin: margin,
        decoration: decoration,
        style: style,
        textAlign: textAlign,
      );

  /// 显示一个 Loading 加载指示器。
  ///
  /// 常用于发起网络请求或较耗时操作的过程反馈。
  ///
  /// 参数：
  /// - [message]：加载文案，可选。
  /// - [backgroundColor]/[borderRadius]：容器底色与圆角。
  /// - [indicatorColor]/[indicatorStrokeWidth]：指示器颜色与线宽。
  /// - [textStyle]：文案样式。
  /// - [customIndicator]：自定义 Widget（通常是图片），如果提供则替代默认的 CircularProgressIndicator，并自动添加旋转动画。
  /// - [rotationDuration]：旋转动画持续时间，默认 `Duration(seconds: 1)`。仅在使用 customIndicator 时生效。
  /// - [showBarrier]：是否显示遮罩层，默认 `true`。
  /// - [barrierDismissible]：点击遮罩是否关闭，默认 `false`（避免误触导致加载中被关）。
  /// - [barrierColor]：遮罩层颜色，默认 `Colors.black54`。
  /// - [animationDuration]：动画持续时间，默认 `150ms`。loading 需要快速显示。
  ///
  /// 返回：
  /// - `String`：此 Loading 的唯一 ID，用于后续关闭。
  ///
  /// 用法示例：
  /// ```dart
  /// final id = Pop.loading(message: '提交中...');
  /// // ... 异步操作完成后
  /// Pop.hideLoading(id);
  /// 
  /// // 使用自定义图片作为 loading 图标
  /// final id2 = Pop.loading(
  ///   message: '加载中',
  ///   customIndicator: Image.asset('assets/loading.png'),
  ///   rotationDuration: Duration(milliseconds: 800),
  /// );
  /// ```
  static String loading({
    String? message,
    Color? backgroundColor,
    double? borderRadius,
    Color? indicatorColor,
    double? indicatorStrokeWidth,
    TextStyle? textStyle,
    Widget? customIndicator,
    Duration rotationDuration = const Duration(seconds: 1),
    bool showBarrier = true,
    bool barrierDismissible = false,
    Color barrierColor = Colors.black54,
    Duration animationDuration = const Duration(milliseconds: 150),
  }) =>
      _loadingImpl(
        message: message,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        indicatorColor: indicatorColor,
        indicatorStrokeWidth: indicatorStrokeWidth,
        textStyle: textStyle,
        customIndicator: customIndicator,
        rotationDuration: rotationDuration,
        showBarrier: showBarrier,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        animationDuration: animationDuration,
      );

  /// 隐藏 Loading。
  ///
  /// 参数：
  /// - [id]：`loading` 返回的唯一 ID。
  ///
  /// 用法示例：
  /// ```dart
  /// final id = Pop.loading();
  /// // ... 任务完成
  /// Pop.hideLoading(id);
  /// ```
  static void hideLoading(String id) => _hideLoadingImpl(id);

  /// 显示一个确认对话框。
  ///
  /// 返回值语义：
  /// - 用户点击"确认"返回 `true`；
  /// - 用户点击"取消"返回 `false`；
  /// - 点击遮罩或关闭按钮返回 `null`。
  ///
  /// 参数：
  /// - [title]：标题，可选。
  /// - [content]：内容（必填）。
  /// - [position]：弹窗位置，默认 `PopupPosition.center`。
  /// - [confirmText]/[cancelText]：按钮文案。若 [cancelText] 为 `null`，仅显示确认按钮。
  /// - [showCloseButton]：右上角关闭按钮，默认 `true`。
  /// - [titleStyle]/[contentStyle]/[confirmStyle]/[cancelStyle]：文字样式。
  /// - [imagePath]：顶部插图路径（如引导/状态图），可选。
  /// - [imageHeight]/[imageWidth]：插图尺寸。
  /// - [textAlign]：内容对齐方式，默认 `TextAlign.center`。
  /// - [buttonLayout]：按钮布局，`row` 或 `column`，默认 `row`。
  /// - [buttonBorderRadius]：按钮圆角。
  /// - [confirmBorder]/[cancelBorder]：按钮边框，如需取消边框传 `null`。
  /// - [confirmBgColor]/[cancelBgColor]：按钮背景色。
  /// - [padding]/[margin]/[decoration]：外观与间距定制。
  /// - [confirmChild]：在内容与按钮之间插入的自定义组件，常用于放置输入框等交互元素。
  /// - [animationDuration]：动画持续时间，默认 `250ms`。confirm 需要适中的动画时长。
  ///
  /// 用法示例：
  /// ```dart
  /// final ok = await Pop.confirm(
  ///   title: '删除确认',
  ///   content: '删除后将不可恢复，是否继续？',
  ///   confirmText: '删除',
  ///   cancelText: '取消',
  ///   buttonLayout: ConfirmButtonLayout.row,
  /// );
  /// if (ok == true) { /* 执行删除 */ }
  /// ```
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
    BoxBorder? confirmBorder,
    BoxBorder? cancelBorder,
    Color? confirmBgColor,
    Color? cancelBgColor,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Decoration? decoration,
    Widget? confirmChild,
    Duration animationDuration = const Duration(milliseconds: 250),
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
        confirmBorder: confirmBorder,
        cancelBorder: cancelBorder,
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
        confirmChild: confirmChild,
        animationDuration: animationDuration,
      );

  /// 显示一个从指定方向滑出的 Sheet 面板。
  ///
  /// 典型用法：列表/表单的抽屉、底部操作面板、选择器容器等。
  ///
  /// 返回值：
  /// - `Future<T?>`：通过内部 `dismiss([result])` 关闭时返回 `result`；
  /// - 点击遮罩关闭返回 `null`。
  ///
  /// 参数：
  /// - [childBuilder]：内容构建器。会注入 `dismiss([T? result])`，用于在子组件中关闭并回传结果。
  ///   例如：`onTap: () => dismiss('item1')`。
  /// - [title]：可选标题。
  /// - [direction]：滑出方向，默认自底部 `SheetDirection.bottom`。
  /// - [showCloseButton]：右上角关闭按钮，默认 `false`。
  /// - [useSafeArea]：是否使用安全区域（刘海/圆角屏适配）。默认遵循内部策略。
  /// - [width]/[height]：尺寸，支持 `SheetDimension` 百分比/固定值等。左右方向默认为屏宽的 75%。
  /// - [maxWidth]/[maxHeight]：最大尺寸。
  /// - [showBarrier]/[barrierDismissible]/[barrierColor]：遮罩设置，默认透明可点空白关闭。
  /// - [imgPath]：可选顶部装饰图。
  /// - [backgroundColor]/[borderRadius]/[boxShadow]：容器外观定制。
  /// - [padding]/[titlePadding]/[titleStyle]/[titleAlign]：间距与标题样式。
  /// - [dockToEdge] / [edgeGap]：保留弹窗所在边缘的交互区域及其间距。
  /// - [animationDuration]：动画持续时间，默认 `400ms`。sheet 需要更长的动画时长。
  /// - [dockToEdge]/[edgeGap]：保留弹窗所在边缘的交互区域及其间距。
  ///
  /// 用法示例：
  /// ```dart
  /// final picked = await Pop.sheet<String>(
  ///   title: '选择操作',
  ///   childBuilder: (dismiss) => ListView(
  ///     children: [
  ///       ListTile(title: Text('复制'), onTap: () => dismiss('copy')),
  ///       ListTile(title: Text('删除'), onTap: () => dismiss('delete')),
  ///     ],
  ///   ),
  ///   direction: SheetDirection.bottom,
  /// );
  /// if (picked == 'delete') { /* 执行删除 */ }
  /// ```
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
    bool? showBarrier,
    bool? barrierDismissible,
    Color? barrierColor,
    String? imgPath,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? titlePadding,
    TextStyle? titleStyle,
    TextAlign? titleAlign,
    bool dockToEdge = false,
    double? edgeGap,
    Duration animationDuration = const Duration(milliseconds: 400),
  }) =>
      _sheetImpl<T>(
        childBuilder: childBuilder,
        title: title,
        direction: direction,
        imgPath: imgPath,
        showCloseButton: showCloseButton,
        useSafeArea: useSafeArea,
        showBarrier: showBarrier,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
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
        dockToEdge: dockToEdge,
        edgeGap: edgeGap,
        animationDuration: animationDuration,
      );

  /// 显示一个日期选择弹窗。
  ///
  /// 返回：
  /// - `Future<DateTime?>`：点击"确认"返回所选日期；取消或点击遮罩返回 `null`。
  ///
  /// 参数：
  /// - [initialDate]：初始选中日期，默认当前时间。
  /// - [minDate]：最小可选日期，默认 `1960-01-01`。
  /// - [maxDate]：最大可选日期，默认当前时间。
  /// - [title]：标题，默认 `'Date of Birth'`。
  /// - [position]：位置，默认 `PopupPosition.bottom`。
  /// - [confirmText]/[cancelText]：按钮文案，默认 `'Confirm'` / `'Cancel'`。
  /// - [activeColor]/[noActiveColor]：选中/未选中颜色。
  /// - [headerBg]：头部背景色。
  /// - [height]：组件内容高度，默认 `180.0`。
  /// - [radius]：圆角，默认 `24.0`。
  /// - [animationDuration]：动画持续时间，默认 `250ms`。date 需要适中的动画时长。
  ///
  /// 用法示例：
  /// ```dart
  /// final date = await Pop.date(
  ///   title: '选择生日',
  ///   minDate: DateTime(1970, 1, 1),
  ///   maxDate: DateTime.now(),
  ///   position: PopupPosition.bottom,
  /// );
  /// if (date != null) { /* 使用 date */ }
  /// ```
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
    Color? headerBg = Colors.blue,
    double? height = 180.0,
    double? radius = 24.0,
    Duration animationDuration = const Duration(milliseconds: 250),
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
      headerBg: headerBg,
      radius: radius,
      animationDuration: animationDuration,
    );


  /// 显示一个锚定的菜单/气泡弹层。
  ///
  /// 返回：
  /// - `Future<T?>`：通过内部 `dismiss([result])` 关闭时返回 `result`；
  /// - 点击空白区域或遮罩关闭返回 `null`。
  ///
  /// 参数：
  /// - [anchorKey]：锚定目标的 `GlobalKey`（必填）。
  /// - [anchorOffset]：相对于目标组件的偏移，默认 `Offset.zero`。
  /// - [builder]：内容构建器。注入 `dismiss([T? result])` 用于关闭并回传。
  /// - [showBarrier]/[barrierDismissible]/[barrierColor]：遮罩设置，默认透明可点空白关闭。
  /// - [animation]/[animationDuration]：动效设置，默认 `fade/200ms`。
  /// - [animationDuration]：动画持续时间，默认 `200ms`。menu 需要快速响应。
  /// - [padding]/[constraints]：内边距和约束。
  /// - [decoration]：容器装饰。
  /// - [constraints]：容器约束。
  static Future<T?> menu<T>({
    required GlobalKey anchorKey,
    Offset anchorOffset = Offset.zero,
    required Widget Function(void Function([T? result]) dismiss) builder,
    bool showBarrier = true,
    bool barrierDismissible = true,
    BoxDecoration? decoration,
    Color? barrierColor,
    PopupAnimation animation = PopupAnimation.fade,
    Duration animationDuration = const Duration(milliseconds: 200),
    EdgeInsetsGeometry? padding,
    BoxConstraints? constraints,
  }) =>
      _menuImpl<T>(
        anchorKey: anchorKey,
        anchorOffset: anchorOffset,
        builder: builder,
        showBarrier: showBarrier,
        barrierDismissible: barrierDismissible,
        decoration: decoration,
        barrierColor: barrierColor ?? Colors.black54,
        animation: animation,
        animationDuration: animationDuration,
        padding: padding,
        constraints: constraints,
      );
}