import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

class ToastPage extends StatelessWidget {
  const ToastPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toast Demo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () => UnifiedPopups.showToast('This is a success toast!', toastType: ToastType.success),
                child: const Text('Show Success Toast'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => UnifiedPopups.showToast('This is a warning toast.', toastType: ToastType.warn),
                child: const Text('Show Warning Toast'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => UnifiedPopups.showToast('This is an error toast.', toastType: ToastType.error),
                child: const Text('Show Error Toast'),
              ),
              ElevatedButton(
                onPressed: () => UnifiedPopups.showToast('This is an error toast.'),
                child: const Text('Show Toast'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
