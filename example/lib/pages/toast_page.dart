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
                onPressed: () => Pop.toast('This is a warning toast.', toastType: ToastType.warn),
                child: const Text('Show Warning Toast'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Pop.toast('This is an error toast.', toastType: ToastType.error),
                child: const Text('Show Error Toast'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Pop.toast('This is an error toast.'),
                child: const Text('Show None Toast'),
              ),
            ],
          ),
        ),
      ),
    )
    );
  }
}
