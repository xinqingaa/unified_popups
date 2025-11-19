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
                    Pop.loading(message: 'loading', showBarrier: false);
                    await Future.delayed(const Duration(seconds: 3));
                    Pop.hideLoading();
                  },
                  child: const Text('Show Loading for 3 seconds'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    Pop.loading(
                      message: '自定义样式 Loading',
                      backgroundColor: Colors.purple.withValues(alpha: 0.9),
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
                    Pop.hideLoading();
                  },
                  child: const Text('自定义样式 Loading'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    Pop.loading(
                      message: '可点击遮罩关闭的 Loading',
                      showBarrier: true,
                      barrierDismissible: true,
                      barrierColor: Colors.black26,
                    );
                    await Future.delayed(const Duration(seconds: 5));
                    Pop.hideLoading();
                  },
                  child: const Text('可关闭 Loading'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    Pop.loading(
                      message: 'loading',
                      customIndicator: Image.asset('assets/loading.png', width: 48, height: 48),
                    );
                    await Future.delayed(const Duration(seconds: 5));
                    Pop.hideLoading();
                  },
                  child: const Text('自定义图片 Loading'),
                ),
                const SizedBox(height: 32),
                // ========== 复现问题的测试按钮 ==========
                ElevatedButton(
                  onPressed: () async {
                    // 第一次调用 loading
                    Pop.loading(message: '第一次 Loading', showBarrier: false);
                    
                    // 立即（或很短延迟）调用第二次 loading
                    // 此时第一个 loading 可能还在关闭动画中
                    await Future.delayed(const Duration(milliseconds: 50));
                    Pop.loading(message: '第二次 Loading', showBarrier: false);
                    
                    // 等待一段时间让动画进行
                    await Future.delayed(const Duration(milliseconds: 2000));
                    
                    // 只调用一次 hideLoading，应该关闭所有，但当前实现可能只关闭一个
                    Pop.hideLoading();
                    
                    // 等待后，测试下方按钮是否可点击
                    await Future.delayed(const Duration(seconds: 2));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('🐛 复现问题：两次loading，一次hide'),
                ),
                const SizedBox(height: 16),
          
                const SizedBox(height: 16),
                // 更极端的测试：快速连续调用多次
                ElevatedButton(
                  onPressed: () async {
                    // 快速连续调用 3 次 loading
                    Pop.loading(message: 'Loading 1', showBarrier: false);
                    await Future.delayed(const Duration(milliseconds: 10));
                    Pop.loading(message: 'Loading 2', showBarrier: false);
                    await Future.delayed(const Duration(milliseconds: 10));
                    Pop.loading(message: 'Loading 3', showBarrier: false);
                    
                    // 等待动画
                    await Future.delayed(const Duration(milliseconds: 2000));
                    
                    // 只调用一次 hideLoading
                    Pop.hideLoading();
                    
                    // 等待后测试
                    await Future.delayed(const Duration(seconds: 2));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('🐛 极端测试：三次loading，一次hide'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}