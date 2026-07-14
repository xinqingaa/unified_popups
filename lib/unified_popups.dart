library unified_popups;

// 导出核心 API
export 'src/apis/pop.dart' show Pop;

// 导出核心管理器和配置（如果需要外部直接访问）
export 'src/core/popup_manager.dart'
    show
        PopupManager,
        PopupConfig,
        PopupPosition,
        PopupAnimation,
        PopupType,
        ToastType,
        ConfirmButtonLayout;

export 'src/configs/sheet_types.dart';

// 工具函数
export 'src/utils/sheet_dimension.dart';

export 'src/widgets/pop_scope_widget.dart';

export 'src/core/popup_route_observer.dart' show PopupRouteObserver;

export 'src/flow_sheets/flow_sheet.dart'
    show
        FlowSheetController,
        FlowSheetNavigator,
        FlowSheetPage,
        FlowSheetPageState,
        FlowSheetRouteBuilder;
