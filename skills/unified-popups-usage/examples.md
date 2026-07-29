# 封装层与业务调用示例

配合 [SKILL.md](SKILL.md)。**写任何 `Pop` / `*Config` 前先按 SKILL「Agent 必读流程」打开对应文档章节**；本文件只示范分层，不替代 `doc/API_REFERENCE.md`。

目标：业务只看见门面；Handle 与 Config 只出现在封装里。完整产品封装见 `example/lib/app/app_pop.dart`。

## 业务代码（推荐形态）

```dart
AppPop.success('已保存');

final ok = await AppPop.confirm(
  title: '删除记录',
  content: '删除后无法恢复',
  destructive: true,
);
if (!ok) return;

await AppPop.runLoading(
  message: '提交中',
  task: () => api.submit(),
);
```

业务侧：无 `Pop`、无 `Config`、无 `Handle`。

## 封装层骨架（Handle 停在这里）

```dart
import 'package:unified_popups/unified_popups.dart';

/// 应用弹层门面。产品代码只依赖本类。
abstract final class AppPop {
  static void success(String message) {
    Pop.toast(
      ToastConfig.text(message, type: ToastType.success),
    );
  }

  static Future<bool> confirm({
    required String title,
    required String content,
    bool destructive = false,
  }) async {
    // 文案、样式、null→false 等映射留在封装层
    return await Pop.confirm(
          ConfirmConfig(
            title: title,
            content: content,
            confirmAction: const ConfirmAction.text('确定'),
            cancelAction: const ConfirmAction.text('取消'),
          ),
        ).result ??
        false;
  }

  /// 业务只传 task；何时开/关 Loading 由封装保证。
  static Future<T> runLoading<T>({
    required String message,
    required Future<T> Function() task,
  }) async {
    final future = task();
    Pop.loading(
      LoadingConfig.text(
        message,
        lifetime: PopupLifetime.until(future),
      ),
    );
    return future;
  }

  static Future<T?> sheet<T>({
    required String title,
    required Widget Function(BuildContext context, void Function(T value) complete)
        build,
  }) {
    return Pop.sheet<T>(
      SheetConfig<T>(
        header: SheetHeaderConfig(title: title),
        builder: (context, handle) => build(
          context,
          (value) => handle.complete(value), // Handle 不传出封装
        ),
      ),
    ).result;
  }
}
```

需要 `requireHandle`、`dismissChannel`、`pause`/`resume` 时：**加在 `AppPop` 上变成业务语义方法**（例如 `AppPop.pauseSheetForDetail()`），不要让页面直接拿 SDK Handle。

## 初始化（App 入口，一次）

```dart
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
  home: const HomePage(),
);
```

## 反例（业务层不要这样）

```dart
// ❌ 页面直连 SDK
final handle = Pop.loading(const LoadingConfig.text('...')).requireHandle();
await handle.dismiss();

// ❌ 业务解读 outcome / 冲突分支
final opened = Pop.confirm(config);
await opened.requireHandle().outcome;

// ❌ 用官方路由弹层混用同一套交互
showDialog(...);
```
