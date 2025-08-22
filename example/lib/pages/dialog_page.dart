import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

class DialogPage extends StatelessWidget {
  const DialogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dialog Demo')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final result = await Pop.confirm(
                    title: 'Confirm Deletion',
                    content: 'Are you sure you want to delete this item?',
                    imagePath: "assets/img.png",
                    buttonLayout:ConfirmButtonLayout.column
                  );
                  print('Confirm result: $result');
                },
                child: const Text('双按钮（行） Confirm Dialog 带图片'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final result = await Pop.confirm(
                    title: 'Confirm Deletion',
                    content: 'Are you sure you want to delete this item?',
                    imagePath: "assets/img.png",
                  );
                  print('Confirm result: $result');
                },
                child: const Text('双按钮（列） Confirm Dialog 带图片'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Pop.confirm(
                    content: "This is a single-button dialog.",
                    confirmText: 'I know',
                    buttonLayout:ConfirmButtonLayout.column,
                    cancelText: null,
                  );
                },
                child: const Text('单按钮 Confirm Dialog'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final result = await Pop.confirm(
                    title: 'Confirm Deletion',
                    content: 'Are you sure you want to delete this item?',
                    buttonBorderRadius: BorderRadius.circular(24),
                    imagePath: "assets/img.png",
                    buttonLayout:ConfirmButtonLayout.column,
                    position: PopupPosition.bottom
                  );
                  print('Confirm result: $result');
                },
                child: const Text(' Confirm Dialog 底部'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Pop.confirm(
                    title: '自定义样式',
                    content: '这是一个完全自定义样式的对话框。',
                    confirmText: '接受',
                    cancelText: '拒绝',
                    showCloseButton: true,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.tealAccent, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    titleStyle: const TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold),
                    contentStyle: const TextStyle(color: Colors.blueGrey, fontSize: 16),
                    confirmBgColor: Colors.green,
                    cancelBgColor: Colors.pink,
                    cancelStyle: const TextStyle(color: Colors.white),
                  );
                },
                child: const Text("完全自定义样式"),
              ),

              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await Pop.confirm(
                    title: '输入信息',
                    content: '请填写下方字段，然后点击确认',
                    // 不做键盘避让，演示遮挡
                    buttonLayout: ConfirmButtonLayout.column,
                    footer: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            labelText: '邮箱',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          decoration: InputDecoration(
                            labelText: '手机',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Confirm 含输入框（不避让键盘）'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
