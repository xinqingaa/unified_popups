import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

// 1. 创建 GlobalKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
  // 3. 初始化 SDK
  // 注意：在实际应用中，你可能希望在 runApp 之后立即调用，
  // 或者使用 WidgetsBinding.instance.addPostFrameCallback 来确保 MaterialApp 已构建。
  // 为了简单起见，我们在这里直接调用。
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PopupManager.initialize(navigatorKey: navigatorKey);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 2. 赋值给 navigatorKey
      navigatorKey: navigatorKey,
      title: 'Unified Popup Example',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
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
                ElevatedButton(
                  onPressed: _showBottomSheet,
                  child: const Text('Show Bottom Sheet Menu'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  key: anchorButtonKey,
                  onPressed: () => _showAnchoredPopup(anchorButtonKey),
                  child: const Text('Show Anchored Popup'),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const Center(child: Text("Multi-Popup Scenarios", style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _showDialogWithToastOnTop,
                  child: const Text('Dialog then Toast on top'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _showBottomSheet() {
    PopupManager.show(
      PopupConfig(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () => PopupManager.hideLast(),
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Get link'),
                onTap: () => PopupManager.hideLast(),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () => PopupManager.hideLast(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        position: PopupPosition.bottom,
        animation: PopupAnimation.slideUp,
        barrierColor: Colors.black.withOpacity(0.3),
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
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Anchored Popup!',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  /// **【新功能演示】**
  /// 先显示一个对话框，然后在这个对话框的按钮上触发一个 Toast。
  /// Toast 会正常显示和消失，而不会影响下方的对话框。
  /// 【新功能演示 - 已优化】
  /// 先显示一个对话框，然后在这个对话框的按钮上触发一个 Toast。
  /// Toast 会正常显示和消失，而不会影响下方的对话框。
  void _showDialogWithToastOnTop() {
    // 1. 直接显示对话框，无需保存ID。
    PopupManager.show(
      PopupConfig(
        barrierDismissible: false, // 禁止点击遮罩关闭
        child: Card(
          margin: const EdgeInsets.all(30),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Multi-Popup Test', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Click the button below to show a Toast on top of this dialog.'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // 2. 在对话框内部，显示一个 Toast。
                    // 这个操作不会关闭当前对话框。
                    UnifiedPopups.showToast('This is a toast!' , position: PopupPosition.top);
                  },
                  child: const Text('Show Toast'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    // 3. 使用 hideLast() 来关闭当前最上层的弹窗，也就是这个对话框本身。
                    // 这种方式更简单，也避免了变量作用域问题。
                    PopupManager.hideAll();
                  },
                  child: const Text('Close Dialog'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}