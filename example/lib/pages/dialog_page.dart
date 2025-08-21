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
                  );
                  print('Confirm result: $result');
                },
                child: const Text('双按钮 Confirm Dialog'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Pop.confirm(
                    content: "This is a single-button dialog.",
                    confirmText: 'I know',
                    cancelText: null,
                  );
                },
                child: const Text('单按钮 Confirm Dialog'),
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
                      gradient: LinearGradient(
                        colors: [Colors.black, Colors.grey.shade200],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    titleStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    contentStyle: const TextStyle(color: Colors.white70, fontSize: 16),
                    confirmBgColor: Colors.green,
                    cancelBgColor: Colors.transparent,
                    cancelStyle: const TextStyle(color: Colors.white),
                  );
                },
                child: const Text("完全自定义样式"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
