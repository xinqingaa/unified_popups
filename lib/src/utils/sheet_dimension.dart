/// 描述 sheet 的宽度或高度：固定像素值或可用屏幕空间的比例。
sealed class SheetDimension {
  /// 固定像素尺寸，例如 [SheetDimension.pixel](300)。
  const factory SheetDimension.pixel(double value) = Pixel;

  /// 可用空间的比例，范围 0.0–1.0，例如 [SheetDimension.fraction](0.8)
  /// 表示 80%。
  const factory SheetDimension.fraction(double value) = Fraction;
}

/// 以固定像素值表示的 [SheetDimension]。
class Pixel implements SheetDimension {
  final double value;

  const Pixel(this.value);
}

/// 以可用空间比例（0.0–1.0）表示的 [SheetDimension]。
class Fraction implements SheetDimension {
  final double value;

  const Fraction(this.value) : assert(value >= 0.0 && value <= 1.0);
}
