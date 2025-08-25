import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScopeWidget(
      child: Scaffold(
      appBar: AppBar(title: const Text('Loading Demo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final loadingId = Pop.loading(message: 'loading');
                  await Future.delayed(const Duration(seconds: 3));
                  Pop.hideLoading(loadingId);
                },
                child: const Text('Show Loading for 3 seconds'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final loadingId = Pop.loading(
                    message: '自定义样式 Loading',
                    backgroundColor: Colors.purple.withOpacity(0.9),
                    borderRadius: 20,
                    indicatorColor: Colors.white,
                    indicatorStrokeWidth: 3,
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                  await Future.delayed(const Duration(seconds: 2));
                  Pop.hideLoading(loadingId);
                },
                child: const Text('自定义样式 Loading'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final loadingId = Pop.loading(
                    message: '可点击遮罩关闭的 Loading',
                    showBarrier: true,
                    barrierDismissible: true,
                    barrierColor: Colors.black26,
                  );
                  await Future.delayed(const Duration(seconds: 5));
                  Pop.hideLoading(loadingId);
                },
                child: const Text('可关闭 Loading'),
              ),
            ],
          ),
        ),
      ),
      )
    ) ;
  }
}
