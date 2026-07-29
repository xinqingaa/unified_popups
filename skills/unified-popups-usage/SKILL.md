---
name: unified-popups-usage
description: >-
  Correct consumption of the unified_popups package for app developers and
  coding agents. Use when integrating or calling popups in a Flutter app that
  depends on unified_popups, designing an AppPop facade, or choosing between
  Pop and showDialog/showModalBottomSheet. Do not use this skill to modify the
  unified_popups package itself.
---

# unified_popups 正确用法（给调用方）

本 skill 面向 **使用本包的应用与 agent**，不是改 `unified_popups` 源码用的。

本文件 **不含** 完整 API / Config 字段。详细用法以文档为准；agent **必须先读文档再写代码**，禁止凭记忆猜参数名或行为。

职责：

1. **强制读文档** —— 见下方「Agent 必读流程」；skill 只指路，不替代文档。
2. **业务不直连 SDK** —— 应用内包 `AppPop`（或等价）；页面 / VM 只调业务语义方法。
3. **Handle / 完整 Config 留在封装层** —— 业务不碰 `PopupHandle`、`requireHandle`、`outcome`、`pause` 等。

分层示例：[examples.md](examples.md)。

## Agent 必读流程（写代码前）

对依赖 `unified_popups` 的任务，**在写出或修改任何弹层相关代码之前**：

1. 用 Read / Grep **打开下表对应文件**（路径相对本包根目录；若在消费方工程，则打开 pub-cache 或 git 依赖中的同名路径）。
2. **只读当前任务相关章节**，不要整份吞进上下文。
3. 文档里没有的写法 → 不要发明；先查文档或 `example/`，仍不确定再问用户。
4. 实现中若缺字段 / 行为不清 → **停下来再读对应章节**，禁止继续猜。

### 按任务打开

| 任务 | 必须先读 |
| --- | --- |
| 首次接入 / 初始化 | `README.md`「30 秒上手」+ `doc/API_REFERENCE.md` §1 初始化 |
| 扩展或新建 `AppPop` 封装 | `doc/API_REFERENCE.md` §3（含 §3.7 App 级二次封装）+ `example/lib/app/app_pop.dart` + 本目录 [examples.md](examples.md) |
| 业务页只调已有门面 | 读项目内 `AppPop`（或等价）；**不必**读完整 API，除非门面缺失要补封装 |
| Toast / Loading / Confirm / Date / Sheet / FlowSheet / Menu / DropMenu / Custom | `doc/API_REFERENCE.md` 对应 §5–§13 **仅一节** |
| `.result` / Handle / 打开被拒 | `doc/API_REFERENCE.md` §3 |
| behavior / barrier / animation / lifetime | `doc/API_REFERENCE.md` §4 对应小节 |
| dismiss / back / pause / 查询 API | `doc/API_REFERENCE.md` §14 |
| 为何不用 `showDialog` | `doc/WHY_OVERLAY.md` |
| 返回键 / 路由策略原理 | `doc/ARCHITECTURE.md`（需要时） |
| v1 迁移 | `doc/MIGRATION_V1_TO_V2.md` |

### `doc/API_REFERENCE.md` 章节速查

写封装层落地某能力时，打开该节再写 Config：

| 能力 | 章节 |
| --- | --- |
| Toast | §5 |
| Loading | §6 |
| Confirm | §7 |
| Date | §8 |
| Sheet | §9 |
| FlowSheet | §10 |
| Menu | §11 |
| DropMenu | §12 |
| Custom | §13 |

**禁止**：未打开上表文档就编写 `Pop.*` / `*Config` / Handle 相关代码。  
**禁止**：把 `API_REFERENCE.md` 全文一次性读入；按节按需。

## 必做：初始化

```dart
MaterialApp(
  navigatorObservers: [Pop.routeObserver],
  builder: Pop.hostBuilder,
  home: const HomePage(),
);
```

细节以 README「30 秒上手」与 API §1 为准，不要只靠本段。

## 必做：应用内再包一层

| 层 | 职责 | 允许 |
| --- | --- | --- |
| 业务（页面 / VM） | 意图：成功提示、确认删除、提交中… | 只调 `AppPop.*` |
| 封装层（`AppPop`） | 文案、样式、默认策略、Loading 生命周期 | `Pop.xxx(Config)`；内部可用 Handle |
| SDK | 完整契约 | 仅封装层与 Lab 直连 |

产品参考：`example/lib/app/app_pop.dart`。API Lab 直连 `Pop` **不是**产品模板。

## 能力选型（意图 → 再去读文档）

选定意图后，**立刻**打开 API 参考对应章节，再在封装层实现：

| 意图 | 去读 |
| --- | --- |
| 轻提示 | §5 Toast |
| 异步等待 | §6 Loading |
| 破坏性确认 | §7 Confirm |
| 选日期 | §8 Date |
| 单页面板 | §9 Sheet |
| 多步向导 | §10 FlowSheet |
| 锚点菜单 | §11 Menu |
| 筛选 / 分组菜单 | §12 DropMenu |
| 其它进同一生命周期 | §13 Custom |

不要用 `showDialog` / `showModalBottomSheet` 替代上表（见 `doc/WHY_OVERLAY.md`）。

## 封装层不变量（细节仍以文档为准）

读完 §3 / 对应能力节后再落实：

- 入口：`Pop.xxx(Config)` → `PopupOpenResult`；业务值 `.result`；控制用 Handle（仅封装内）。
- Loading 必须有关闭路径（见 §6 / `PopupLifetime`）。
- Sheet / Menu / Custom 用 builder 注入的 handle 完成/关闭（见 §3.4、§9+）。
- FlowSheet 收尾与 `onBack` 见 §10。
- 只 import `package:unified_popups/unified_popups.dart`。

## 检查清单

- [ ] 已按「Agent 必读流程」打开过本任务所需文档章节
- [ ] 初始化依据 README / §1，而非猜测
- [ ] 产品代码走门面；Handle 未泄漏到业务
- [ ] Config 字段来自 API 参考，无臆造参数
- [ ] 未把整份 API 参考塞进上下文

## 不是本 skill 的范围

- 修改 `unified_popups` 包本身 → 不用本 skill。
- 用本 skill 代替阅读 `doc/API_REFERENCE.md` → 不允许。
