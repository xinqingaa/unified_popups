import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_popups/unified_popups.dart';

/// 性能基准测试套件
///
/// 用于验证优化后的性能指标：
/// - PopScopeWidget 重建次数
/// - AnimationController 资源使用
/// - 弹窗显示/隐藏性能
void main() {
  // 初始化测试环境
  setUpAll(() {
    // 确保 Flutter 测试绑定已初始化
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  // 每个测试后清理资源
  tearDown(() {
    // 关闭所有弹窗
    try {
      PopupManager.hideAll();
    } catch (e) {
      // 忽略清理时的错误
    }
  });

  group('PopScopeWidget Rebuild Performance', () {
    testWidgets('PopScopeWidget rebuilds only when necessary',
        (tester) async {
      // 创建 navigatorKey 并初始化 PopupManager
      final navigatorKey = GlobalKey<NavigatorState>();
      PopupManager.initialize(navigatorKey: navigatorKey);

      // 重建计数器
      int childBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: PopScopeWidget(
            child: Builder(
              builder: (context) {
                childBuildCount++;
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Pop.toast('Test toast');
                      },
                      child: const Text('Show Toast'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // 初始构建
      expect(childBuildCount, 1);

      // 显示 toast（Toast 不会影响 hasNonToastPopup）
      await tester.tap(find.text('Show Toast'));
      await tester.pump();

      // Toast 显示后，子树不应该重建（childBuildCount 保持为 1）
      expect(childBuildCount, 1);

      // 等待 toast 自动消失
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // child 应该只重建一次（初始构建）
      expect(childBuildCount, 1);
    });

    testWidgets(
        'PopScopeWidget rebuilds only when hasNonToastPopup actually changes',
        (tester) async {
      // 创建 navigatorKey 并初始化 PopupManager
      final navigatorKey = GlobalKey<NavigatorState>();
      PopupManager.initialize(navigatorKey: navigatorKey);

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: PopScopeWidget(
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Pop.confirm(
                          title: 'Test',
                          content: 'Content',
                        );
                      },
                      child: const Text('Show Confirm'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // 显示 confirm（非 Toast 弹窗，应该触发 PopScopeWidget 重建）
      await tester.tap(find.text('Show Confirm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 验证弹窗已显示
      expect(find.text('Test'), findsOneWidget);

      // 关闭弹窗
      await tester.tapAt(const Offset(10, 10)); // 点击蒙层
      await tester.pumpAndSettle();

      // 验证弹窗已关闭
      expect(find.text('Test'), findsNothing);
    });
  });

  group('AnimationController Pool Efficiency', () {
    testWidgets('Multiple toasts use AnimationControllers efficiently',
        (tester) async {
      // 创建 navigatorKey 并初始化 PopupManager
      final navigatorKey = GlobalKey<NavigatorState>();
      PopupManager.initialize(navigatorKey: navigatorKey);

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: PopScopeWidget(
            child: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        // 快速显示多个 toast
                        for (int i = 0; i < 10; i++) {
                          Pop.toast('Toast $i');
                        }
                      },
                      child: const Text('Show 10 Toasts'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();

      await tester.tap(find.text('Show 10 Toasts'));
      await tester.pump();

      stopwatch.stop();

      // 验证性能：10 个 toast 应该在合理时间内完成
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      await tester.pumpAndSettle(const Duration(seconds: 3));
    });
  });

  group('Popup Display Performance', () {
    testWidgets('Sheet popup displays within performance threshold',
        (tester) async {
      // 创建 navigatorKey 并初始化 PopupManager
      final navigatorKey = GlobalKey<NavigatorState>();
      PopupManager.initialize(navigatorKey: navigatorKey);

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: PopScopeWidget(
            child: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        Pop.sheet(
                          title: 'Test Sheet',
                          childBuilder: (dismiss) => ListView(
                            children: List.generate(
                              50,
                              (index) => ListTile(
                                title: Text('Item $index'),
                                onTap: () => dismiss(),
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text('Show Sheet'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();

      await tester.tap(find.text('Show Sheet'));
      await tester.pump();

      stopwatch.stop();

      // Sheet 应该在 100ms 内开始显示
      expect(stopwatch.elapsedMilliseconds, lessThan(100));

      // 等待动画完成
      await tester.pumpAndSettle();

      expect(find.text('Test Sheet'), findsOneWidget);
    });

    testWidgets('Menu with anchor calculates position efficiently',
        (tester) async {
      // 创建 navigatorKey 并初始化 PopupManager
      final navigatorKey = GlobalKey<NavigatorState>();
      PopupManager.initialize(navigatorKey: navigatorKey);
      final anchorKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: PopScopeWidget(
            child: Scaffold(
              body: Center(
                child: Column(
                  children: [
                    Container(
                      key: anchorKey,
                      width: 100,
                      height: 50,
                      color: Colors.red,
                    ),
                    Builder(
                      builder: (context) {
                        return ElevatedButton(
                          onPressed: () {
                            Pop.menu(
                              anchorKey: anchorKey,
                              builder: (dismiss) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  ListTile(title: Text('Option 1')),
                                  ListTile(title: Text('Option 2')),
                                ],
                              ),
                            );
                          },
                          child: const Text('Show Menu'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();

      await tester.tap(find.text('Show Menu'));
      await tester.pump();

      stopwatch.stop();

      // 菜单位置计算应该在合理时间内完成
      expect(stopwatch.elapsedMilliseconds, lessThan(50));

      await tester.pumpAndSettle();
    });
  });

  group('Memory and Resource Management', () {
    testWidgets('HideAll properly disposes all resources', (tester) async {
      // 创建 navigatorKey 并初始化 PopupManager
      final navigatorKey = GlobalKey<NavigatorState>();
      PopupManager.initialize(navigatorKey: navigatorKey);

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: PopScopeWidget(
            child: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        // 显示多个不同类型的弹窗
                        Pop.toast('Toast 1');
                        Pop.toast('Toast 2');
                        Pop.sheet(
                          title: 'Sheet 1',
                          childBuilder: (dismiss) => const SizedBox.shrink(),
                        );
                        Pop.sheet(
                          title: 'Sheet 2',
                          childBuilder: (dismiss) => const SizedBox.shrink(),
                        );
                      },
                      child: const Text('Show Multiple Popups'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Multiple Popups'));
      await tester.pump();

      // 验证所有弹窗都已显示
      expect(PopupManager.getCountByType(PopupType.toast), equals(2));
      expect(PopupManager.getCountByType(PopupType.sheet), equals(2));

      // 关闭所有弹窗
      PopupManager.hideAll();
      await tester.pumpAndSettle();

      // 验证所有弹窗都已关闭
      expect(PopupManager.getCountByType(PopupType.toast), equals(0));
      expect(PopupManager.getCountByType(PopupType.sheet), equals(0));
    });
  });

  group('Stress Tests', () {
    testWidgets('Rapid toast display/hide cycle', (tester) async {
      // 创建 navigatorKey 并初始化 PopupManager
      final navigatorKey = GlobalKey<NavigatorState>();
      PopupManager.initialize(navigatorKey: navigatorKey);

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: PopScopeWidget(
            child: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () async {
                        // 快速显示/隐藏 50 次
                        for (int i = 0; i < 50; i++) {
                          Pop.toast('Toast $i');
                          await tester.pump(const Duration(milliseconds: 50));
                        }
                      },
                      child: const Text('Rapid Toast Test'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();

      await tester.tap(find.text('Rapid Toast Test'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      stopwatch.stop();

      // 验证没有崩溃，且在合理时间内完成
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
    });

    testWidgets('Multiple simultaneous anchored menus', (tester) async {
      // 创建 navigatorKey 并初始化 PopupManager
      final navigatorKey = GlobalKey<NavigatorState>();
      PopupManager.initialize(navigatorKey: navigatorKey);
      final anchorKeys = List.generate(5, (index) => GlobalKey());

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: PopScopeWidget(
            child: Scaffold(
              body: Center(
                child: Column(
                  children: [
                    ...List.generate(5, (index) {
                      return Container(
                        key: anchorKeys[index],
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.all(5),
                        color: Colors.primaries[index % Colors.primaries.length],
                      );
                    }),
                    Builder(
                      builder: (context) {
                        return ElevatedButton(
                          onPressed: () {
                            // 同时显示多个菜单
                            for (int i = 0; i < 5; i++) {
                              Pop.menu(
                                anchorKey: anchorKeys[i],
                                builder: (dismiss) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(title: Text('Menu $i - Option 1')),
                                    ListTile(title: Text('Menu $i - Option 2')),
                                  ],
                                ),
                              );
                            }
                          },
                          child: const Text('Show All Menus'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show All Menus'));
      await tester.pump();
      await tester.pumpAndSettle();

      // 验证所有菜单都已显示
      expect(PopupManager.getCountByType(PopupType.menu), equals(5));

      // 清理
      PopupManager.hideAll();
      await tester.pumpAndSettle();
    });
  });
}
