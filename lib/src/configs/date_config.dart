import 'package:flutter/material.dart';

import '../controller/popup_lifecycle_callbacks.dart';
import '../controller/popup_ownership.dart';
import 'popup_animation_config.dart';
import 'popup_back_policy.dart';
import 'popup_barrier_config.dart';
import 'popup_behavior_config.dart';
import 'popup_owner_policy.dart';
import 'popup_position.dart';
import 'popup_route_policy.dart';
import 'popup_visual_config.dart';

/// [DateConfig] 的可选日期范围与初始选中日期。
final class DateRangeConfig {
  /// 创建一个日期范围，将日期归一化到零点并校验边界。
  ///
  /// 当 [minDate] 晚于 [maxDate]，或 [initialDate] 超出范围时抛出
  /// [ArgumentError]。
  factory DateRangeConfig({
    required DateTime initialDate,
    required DateTime minDate,
    required DateTime maxDate,
  }) {
    final initial = DateUtils.dateOnly(initialDate);
    final min = DateUtils.dateOnly(minDate);
    final max = DateUtils.dateOnly(maxDate);
    if (min.isAfter(max)) {
      throw ArgumentError.value(
        minDate,
        'minDate',
        'must be on or before maxDate',
      );
    }
    if (initial.isBefore(min) || initial.isAfter(max)) {
      throw ArgumentError.value(
        initialDate,
        'initialDate',
        'must be within minDate and maxDate',
      );
    }
    return DateRangeConfig._(initial, min, max);
  }

  const DateRangeConfig._(this.initialDate, this.minDate, this.maxDate);

  final DateTime initialDate;
  final DateTime minDate;
  final DateTime maxDate;
}

/// 日期选择器头部与操作按钮的本地化文案。
final class DateLabels {
  /// 创建带默认值的文案配置。
  const DateLabels({
    this.title = 'Date of Birth',
    this.confirm = 'Confirm',
    this.cancel,
  });

  final String title;
  final String confirm;
  final String? cancel;
}

/// 日期选择器面板的视觉样式。
final class DateStyle {
  /// 创建日期选择器外观设置。
  const DateStyle({
    this.activeColor,
    this.inactiveColor,
    this.headerBackgroundColor,
    this.height = 216,
    this.radius = 16,
  })  : assert(height > 0),
        assert(radius >= 0);

  final Color? activeColor;
  final Color? inactiveColor;
  final Color? headerBackgroundColor;
  final double height;
  final double radius;
}

/// [Pop.date] 的配置：带可滚动日期选择器的底部面板。
final class DateConfig implements PopupVisualConfig {
  /// 创建一个带可选边界的日期选择器。
  ///
  /// 默认值：[minDate] 为 1960-01-01，[maxDate] 为今天，[initialDate] 为今天
  /// （会被裁剪到范围内）。若已持有一个 [DateRangeConfig]，优先使用
  /// [DateConfig.range]。
  factory DateConfig({
    DateTime? initialDate,
    DateTime? minDate,
    DateTime? maxDate,
    DateLabels labels = const DateLabels(),
    DateStyle style = const DateStyle(),
    PopupBehaviorConfig behavior = const PopupBehaviorConfig(
      routePolicy: PopupRoutePolicy.dismissWhenOwnerRouteChanges,
      backPolicy: PopupBackPolicy.dismiss,
    ),
    PopupOwnership ownership = const PopupOwnership(
      policy: PopupOwnerPolicy.dismissWithParent,
    ),
    PopupBarrierConfig barrier = const PopupBarrierConfig(),
    PopupPosition position = PopupPosition.bottom,
    PopupAnimationConfig animationConfig = const PopupAnimationConfig(
      type: PopupAnimationType.slideUp,
      duration: Duration(milliseconds: 250),
    ),
    PopupLifecycleCallbacks<DateTime> lifecycle =
        const PopupLifecycleCallbacks<DateTime>(),
  }) {
    final today = DateUtils.dateOnly(DateTime.now());
    final min = DateUtils.dateOnly(minDate ?? DateTime(1960));
    final max = DateUtils.dateOnly(maxDate ?? today);
    final requested = DateUtils.dateOnly(initialDate ?? today);
    final initial = requested.isBefore(min)
        ? min
        : requested.isAfter(max)
            ? max
            : requested;
    return DateConfig.range(
      range: DateRangeConfig(
        initialDate: initial,
        minDate: min,
        maxDate: max,
      ),
      labels: labels,
      style: style,
      behavior: behavior,
      ownership: ownership,
      barrier: barrier,
      position: position,
      animationConfig: animationConfig,
      lifecycle: lifecycle,
    );
  }

  /// 从一个明确的 [range] 创建日期选择器。
  const DateConfig.range({
    required this.range,
    this.labels = const DateLabels(),
    this.style = const DateStyle(),
    this.behavior = const PopupBehaviorConfig(
      routePolicy: PopupRoutePolicy.dismissWhenOwnerRouteChanges,
      backPolicy: PopupBackPolicy.dismiss,
    ),
    this.ownership = const PopupOwnership(
      policy: PopupOwnerPolicy.dismissWithParent,
    ),
    this.barrier = const PopupBarrierConfig(),
    this.position = PopupPosition.bottom,
    this.animationConfig = const PopupAnimationConfig(
      type: PopupAnimationType.slideUp,
      duration: Duration(milliseconds: 250),
    ),
    this.lifecycle = const PopupLifecycleCallbacks<DateTime>(),
  });

  final DateRangeConfig range;
  final DateLabels labels;
  final DateStyle style;
  final PopupBehaviorConfig behavior;
  final PopupOwnership ownership;

  @override
  final PopupBarrierConfig barrier;

  @override
  final PopupPosition position;

  @override
  final PopupAnimationConfig animationConfig;
  final PopupLifecycleCallbacks<DateTime> lifecycle;
}
