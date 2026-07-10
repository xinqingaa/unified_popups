import 'popup_animation_config.dart';
import 'popup_barrier_config.dart';
import 'popup_position.dart';

abstract interface class PopupVisualConfig {
  PopupAnimationConfig get animationConfig;
  PopupBarrierConfig get barrier;
  PopupPosition get position;
}
