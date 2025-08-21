/// 定义弹窗的尺寸，可以是固定像素或屏幕比例
sealed class SheetDimension {
  /// 固定像素值
  /// e.g., SheetDimension.pixel(300)
  const factory SheetDimension.pixel(double value) = Pixel;

  /// 占屏幕可用空间的分数（0.0 to 1.0）
  /// e.g., SheetDimension.fraction(0.8) for 80%
  const factory SheetDimension.fraction(double value) = Fraction;
}

class Pixel implements SheetDimension {
  final double value;
  const Pixel(this.value);
}

class Fraction implements SheetDimension {
  final double value;
  const Fraction(this.value) : assert(value >= 0.0 && value <= 1.0);
}
