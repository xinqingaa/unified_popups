import 'package:example/home_page.dart';
import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import 'calendar_view.dart';

//  创建 GlobalKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
  // 注意：在实际应用中，希望在 runApp 之后立即调用，
  // 使用 WidgetsBinding.instance.addPostFrameCallback 来确保 MaterialApp 已构建。
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PopupManager.initialize(navigatorKey: navigatorKey);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 赋值给 navigatorKey
      navigatorKey: navigatorKey,
      title: 'Unified Popup Example',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
      routes: {
        "/home": (context) => const HomePage()
      },
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey anchorButtonKey = GlobalKey();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unified Popup Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_fullscreen),
            tooltip: 'Hide All Popups',
            onPressed: () {
              PopupManager.hideAll();
            },
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // 使用 Toast
                ElevatedButton(
                  onPressed: () => UnifiedPopups.showToast('This is a toast!', position: PopupPosition.top),
                  child: Text('Show Toast'),
                ),
                const SizedBox(height: 12),
                // 使用 Loading
                ElevatedButton(
                  onPressed: () async {
                    final loadingId = UnifiedPopups.showLoading();
                    await Future.delayed(Duration(seconds: 2));
                    UnifiedPopups.hideLoading(loadingId);
                  },
                  child: Text('Show Loading'),
                ),
                const SizedBox(height: 12),
                // 使用 Confirm Dialog
                ElevatedButton(
                  onPressed: () async {
                    final result = await UnifiedPopups.showConfirm(
                      title: 'Confirm Deletion',
                      content: 'Are you sure you want to delete this item?',
                    );
                    print('Confirm result: $result'); // true, false, or null
                  },
                  child: Text('双按钮 Confirm Dialog'),
                ),

                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    final result = await UnifiedPopups.showConfirm(
                      content: "test showConfirm",
                      confirmText: 'i kown' ,
                      cancelText: null,
                    );
                  },
                  child: const Text('单按钮 Confirm Dialog'),
                ),

                const SizedBox(height: 12,),
                ElevatedButton(
                  onPressed: () async {
                    final result = await UnifiedPopups.showConfirm(
                      title: '自定义样式',
                      content: '这是一个完全自定义样式的对话框。',
                      confirmText: '接受',
                      cancelText: '拒绝',
                      showCloseButton: true,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black, Colors.grey.shade200],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      titleStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      contentStyle: const TextStyle(color: Colors.white70, fontSize: 16),
                      confirmBgColor: Colors.green,
                      cancelBgColor: Colors.transparent,
                      cancelStyle: const TextStyle(color: Colors.white),
                    );
                  },
                  child: Text("完全自定义样式"),
                ),
                const SizedBox(height: 12),
                // 经典的底部 Sheet
                ElevatedButton(
                  child: const Text('Show Bottom Sheet'),
                  onPressed: () async {
                    final result = await UnifiedPopups.showSheet<String>(
                      context,
                      title: '选择操作',
                      childBuilder: (dismiss) {
                        return ListView(
                          shrinkWrap: true, // 重要：让 ListView 自适应内容高度
                          children: [
                            ListTile(title: const Text('分享'), onTap: () => dismiss('share')),
                            ListTile(title: const Text('编辑'), onTap: () => dismiss('edit')),
                            ListTile(title: const Text('删除'), onTap: () => dismiss('delete'),),
                            ListTile(title: const Text('取消'), onTap: () => dismiss()), // 不带参数关闭
                          ],
                        );
                      },
                    );
                    if (result != null) {
                      UnifiedPopups.showToast('你选择了: $result');
                    } else {
                      UnifiedPopups.showToast('关闭了sheet');
                    }
                  },
                ),
                const SizedBox(height: 12),
                // 左侧抽屉
                ElevatedButton(
                  child: const Text('Show Left Drawer'),
                  onPressed: () async {
                    final result = await UnifiedPopups.showSheet<String>(
                      context,
                      direction: SheetDirection.left,
                      title: '菜单',
                      childBuilder: (dismiss) => ListView(
                        children: [
                          ListTile(leading: const Icon(Icons.home), title: const Text('首页'), onTap: () => dismiss('home')),
                          ListTile(leading: const Icon(Icons.settings), title: const Text('设置'), onTap: () => dismiss('setting')),
                        ],
                      ),
                    );
                    if (result != null) {
                      UnifiedPopups.showToast('你选择了: $result');
                    } else {
                      UnifiedPopups.showToast('关闭了sheet');
                    }
                  },
                ),
                const SizedBox(height: 12),
                //  顶部通知栏
                ElevatedButton(
                  child: const Text('Show Top Notification'),
                  onPressed: () {
                    UnifiedPopups.showSheet(
                      context,
                      direction: SheetDirection.top,
                      title: '新消息',
                      backgroundColor: Colors.amber.shade100,
                      childBuilder: (dismiss) => ListTile(
                        title: const Text('您的快递已到达'),
                        subtitle: const Text('点击查看详情'),
                        onTap: () => dismiss(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  key: anchorButtonKey,
                  onPressed: () => _showAnchoredPopup(anchorButtonKey),
                  child: const Text('Show Anchored Popup'),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed:() {
                    Navigator.of(context).pushNamed("/home");
                  },
                  child: const Text('进入日历测试页面'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  void _showAnchoredPopup(GlobalKey anchorKey) {
    PopupManager.show(
      PopupConfig(
        anchorKey: anchorKey,
        anchorOffset: const Offset(0, 8),
        animation: PopupAnimation.fade,
        showBarrier: true,
        barrierColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade700,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Anchored Popup!',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}