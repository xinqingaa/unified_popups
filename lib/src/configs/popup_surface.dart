import 'package:flutter/widgets.dart';

import '../widgets/liquid_glass/liquid_glass_style.dart';

/// 交给 [PopupSurface.builder] 的内容与圆角。
///
/// [child] 已包含标题、按钮、拖拽条和安全区内边距。圆角、模糊、填充色和阴影由
/// builder 自己绘制。
@immutable
final class PopupSurfaceChild {
  /// 创建一个壳插槽。
  const PopupSurfaceChild({
    required this.child,
    required this.borderRadius,
  });

  /// 面板内容。
  final Widget child;

  /// Confirm 默认 12；Sheet 未指定时为进入边外角 32；Menu 默认 8；
  /// DropMenu 默认 18。
  final BorderRadius borderRadius;
}

/// 用外部组件替换 Confirm、Sheet、Menu、DropMenu 的容器壳。
typedef PopupSurfaceBuilder = Widget Function(
  BuildContext context,
  PopupSurfaceChild child,
);

/// Confirm、Sheet、FlowSheet、Menu、DropMenu 的容器壳。
///
/// [PopupSurface.solid] 保持实色容器。[PopupSurface.glass] 使用液态玻璃。
/// [PopupSurface.builder] 把壳交给调用方。尺寸、拖拽、键盘、安全区和菜单摆放
/// 仍由库负责。Confirm、Sheet、FlowSheet、Menu 默认实色；DropMenu 默认玻璃。
@immutable
sealed class PopupSurface {
  const PopupSurface();

  /// 实色容器。Confirm 和 Menu 使用 decoration；Sheet 使用背景色和阴影。
  const factory PopupSurface.solid() = SolidPopupSurface;

  /// 液态玻璃容器。
  ///
  /// 圆角来自各 Style 的 borderRadius：Confirm 默认 12，Sheet 未指定时进入边
  /// 外角 32，Menu 默认 8，DropMenu 默认 18。不会使用 LiquidGlass 的胶囊默认值。
  /// 玻璃模式下 Confirm / Menu 的 decoration、Sheet 的 backgroundColor 与
  /// boxShadow 不参与绘制。
  const factory PopupSurface.glass({
    LiquidGlassStyle style,
    double? blurSigma,
    Duration blurDelay,
    bool enableShadow,
    BlendMode backdropBlendMode,
  }) = GlassPopupSurface;

  /// 外部容器。builder 负责裁剪、背景和阴影。
  const factory PopupSurface.builder(PopupSurfaceBuilder builder) =
      BuilderPopupSurface;
}

/// 实色壳。
final class SolidPopupSurface extends PopupSurface {
  /// 创建一个实色壳。
  const SolidPopupSurface();
}

/// 内置液态玻璃壳。
final class GlassPopupSurface extends PopupSurface {
  /// 创建一个液态玻璃壳。
  const GlassPopupSurface({
    this.style = LiquidGlassStyle.standard,
    this.blurSigma,
    this.blurDelay = Duration.zero,
    this.enableShadow = true,
    this.backdropBlendMode = BlendMode.src,
  });

  /// 玻璃颜色、描边和模糊强度。
  final LiquidGlassStyle style;

  /// 覆盖 [LiquidGlassStyle.blurSigma]。
  final double? blurSigma;

  /// 延迟开启模糊，避开入场第一帧的开销。
  final Duration blurDelay;

  /// 是否绘制 [LiquidGlassStyle] 的阴影。
  final bool enableShadow;

  /// [BackdropFilter] 与背后内容的混合模式。
  final BlendMode backdropBlendMode;
}

/// 调用方提供的容器壳。
final class BuilderPopupSurface extends PopupSurface {
  /// 创建一个外部容器壳。
  const BuilderPopupSurface(this.builder);

  /// 接收内容和圆角，返回完整容器。
  final PopupSurfaceBuilder builder;
}
