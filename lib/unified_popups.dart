library unified_popups;
// 导出核心 API
export 'src/apis/pop.dart' show Pop;

// 导出核心管理器和配置（如果需要外部直接访问）
export 'src/core/popup_manager.dart' show PopupManager, PopupConfig, PopupPosition, PopupAnimation , SheetDirection , ToastType;

// 工具函数
export 'src/utils/sheet_dimension.dart';