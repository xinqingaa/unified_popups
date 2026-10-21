/// 可单独使用的液态玻璃表面。
///
/// 用 LiquidGlassStyle 改颜色、模糊、描边和阴影。描边可以继承
/// LiquidGlassEdgePainter，或传给 LiquidGlass.edgePainterBuilder。
/// 单独使用时 enableShadow 默认关闭，混合模式默认 srcOver，圆角默认胶囊。
///
/// 弹层壳的开关是 PopupSurface（从 unified_popups.dart 引入），挂在
/// ConfirmStyle、SheetStyle、PopupMenuStyle、DropMenuStyle 的 surface 上。
/// Confirm、Sheet、FlowSheet、Menu 默认实色，DropMenu 默认玻璃。玻璃参数、
/// 圆角和外部容器的边界见 PopupSurface。
library liquid_glass;

export 'src/widgets/liquid_glass/liquid_glass.dart';
export 'src/widgets/liquid_glass/liquid_glass_action_button.dart';
export 'src/widgets/liquid_glass/liquid_glass_button.dart';
export 'src/widgets/liquid_glass/liquid_glass_edge_painter.dart';
export 'src/widgets/liquid_glass/liquid_glass_style.dart';
