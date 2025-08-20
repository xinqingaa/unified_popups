import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loading Demo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () async {
              final loadingId = UnifiedPopups.showLoading(message: '正在加载...');
              await Future.delayed(const Duration(seconds: 3));
              UnifiedPopups.hideLoading(loadingId);
            },
            child: const Text('Show Loading for 3 seconds'),
          ),
        ),
      ),
    );
  }
}
