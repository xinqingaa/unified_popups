import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

class ToastPage extends StatelessWidget {
  const ToastPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScopeWidget(
      child: Scaffold(
      appBar: AppBar(title: const Text('Toast Demo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () => Pop.toast(
                  'This is a success toast!',
                  toastType: ToastType.success,
                  position: PopupPosition.bottom,
                ),
                child: const Text('Show Success Toast （bottom）'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Pop.toast('This is a warning toast.', toastType: ToastType.warn, ),
                child: const Text('Show Warning Toast'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Pop.toast('This is an error toast.', toastType: ToastType.error),
                child: const Text('Show Error Toast'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Pop.toast('This phone number is not registered. Please use the verification code to log in and register first.'),
                child: const Text('Show None Toast'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Pop.toast(
                  '这是一个自定义样式的 Toast',
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('自定义样式 Toast'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Pop.toast(
                  '带遮罩的 Toast，点击遮罩关闭',
                  showBarrier: true,
                  barrierDismissible: true,
                  duration: const Duration(seconds: 5),
                ),
                child: const Text('带遮罩 Toast'),
              ),
            ],
          ),
        ),
      ),
    )
    );
  }
}
