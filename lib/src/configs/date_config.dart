import 'package:flutter/material.dart';

import '../controller/popup_lifecycle_callbacks.dart';
import '../controller/popup_ownership.dart';
import 'popup_animation_config.dart';
import 'popup_back_policy.dart';
import 'popup_barrier_config.dart';
import 'popup_behavior_config.dart';
import 'popup_channel.dart';
import 'popup_owner_policy.dart';
import 'popup_position.dart';
import 'popup_route_policy.dart';
import 'popup_visual_config.dart';

final class DateRangeConfig {
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

final class DateLabels {
  const DateLabels({
    this.title = 'Date of Birth',
    this.confirm = 'Confirm',
    this.cancel,
  });

  final String title;
  final String confirm;
  final String? cancel;
}

final class DateStyle {
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

final class DateConfig implements PopupVisualConfig {
  const DateConfig({
    required this.range,
    this.labels = const DateLabels(),
    this.style = const DateStyle(),
    this.behavior = const PopupBehaviorConfig(
      channel: PopupChannel.date,
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
