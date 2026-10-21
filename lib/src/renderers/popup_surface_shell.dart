import 'package:flutter/widgets.dart';

import '../configs/popup_surface.dart';
import '../widgets/liquid_glass/liquid_glass.dart';
import 'popup_entry_animation.dart';

/// 玻璃或外部容器壳。实色路径由各 Renderer 保持原有装饰。
class PopupSurfaceShell extends StatelessWidget {
  /// 用 [surface] 包裹 [child]。
  const PopupSurfaceShell({
    required this.surface,
    required this.borderRadius,
    required this.child,
    super.key,
  });

  /// 玻璃或 builder。传入实色时直接返回 [child]。
  final PopupSurface surface;

  /// 传给玻璃或 builder 的圆角。
  final BorderRadius borderRadius;

  /// 标题、按钮和安全区之内的内容。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final content = PopupEntryAnimation.fadeContent(context, child);
    return switch (surface) {
      SolidPopupSurface() => child,
      GlassPopupSurface(
        :final style,
        :final blurSigma,
        :final blurDelay,
        :final enableShadow,
        :final backdropBlendMode,
      ) =>
        LiquidGlass(
          borderRadius: borderRadius,
          style: style,
          blurSigma: blurSigma,
          blurDelay: blurDelay,
          enableShadow: enableShadow,
          backdropBlendMode: backdropBlendMode,
          child: content,
        ),
      BuilderPopupSurface(:final builder) => builder(
          context,
          PopupSurfaceChild(child: content, borderRadius: borderRadius),
        ),
    };
  }
}
