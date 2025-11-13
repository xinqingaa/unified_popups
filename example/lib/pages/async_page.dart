import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

class AsyncPage extends StatefulWidget {
  const AsyncPage({super.key});

  @override
  State<AsyncPage> createState() => _AsyncPageState();
}

class _AsyncPageState extends State<AsyncPage> {
  String _lastResult = '';

  void _updateResult(String result) {
    setState(() {
      _lastResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeWidget(
      child: Scaffold(
        appBar: AppBar(title: const Text('异步场景测试')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_lastResult.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _lastResult.contains('成功')
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _lastResult.contains('成功')
                          ? Colors.green
                          : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '上次结果: $_lastResult',
                    style: TextStyle(
                      color: _lastResult.contains('成功')
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              _buildTestButton(
                title: '场景1: Future.then() 回调',
                subtitle: '模拟网络请求完成后的回调中调用 loading',
                onPressed: _testFutureThen,
              ),
              const SizedBox(height: 12),
              _buildTestButton(
                title: '场景2: async/await 中间调用',
                subtitle: '在异步操作中间调用 loading',
                onPressed: _testAsyncAwait,
              ),
              const SizedBox(height: 12),
              _buildTestButton(
                title: '场景3: Stream 监听',
                subtitle: '在 Stream 监听回调中调用 loading',
                onPressed: _testStream,
              ),
              const SizedBox(height: 12),
              _buildTestButton(
                title: '场景4: Timer 回调',
                subtitle: '在 Timer 回调中调用 loading',
                onPressed: _testTimer,
              ),
              const SizedBox(height: 12),
              _buildTestButton(
                title: '场景5: postFrameCallback',
                subtitle: '最关键的测试：在构建阶段调用 loading',
                onPressed: _testPostFrameCallback,
                isCritical: true,
              ),
              const SizedBox(height: 12),
              _buildTestButton(
                title: '场景6: initState 异步调用',
                subtitle: '在 StatefulWidget 初始化时异步调用 loading',
                onPressed: _testInitStateAsync,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
    bool isCritical = false,
  }) {
    return Card(
      elevation: isCritical ? 4 : 2,
      color: isCritical ? Colors.orange.withValues(alpha: 0.1) : null,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCritical ? Colors.orange.shade700 : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isCritical ? Colors.orange : null,
          ),
          child: const Text('测试'),
        ),
      ),
    );
  }

  /// 场景1: Future.then() 回调中调用 loading
  void _testFutureThen() {
    _updateResult('');
    try {
      // 模拟网络请求
      Future.delayed(const Duration(milliseconds: 100))
          .then((_) {
        // 在 then 回调中调用 loading
        Pop.loading(message: '处理数据中...');
        Future.delayed(const Duration(seconds: 2)).then((_) {
          Pop.hideLoading();
          _updateResult('场景1: 成功 - Future.then() 回调中调用 loading 正常');
          Pop.toast('场景1测试成功', toastType: ToastType.success);
        });
      });
    } catch (e) {
      _updateResult('场景1: 失败 - $e');
      Pop.toast('场景1测试失败: $e', toastType: ToastType.error);
    }
  }

  /// 场景2: async/await 中间调用 loading
  Future<void> _testAsyncAwait() async {
    _updateResult('');
    try {
      // 第一步异步操作
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 在中间调用 loading
      Pop.loading(message: '继续处理中...');
      
      // 第二步异步操作
      await Future.delayed(const Duration(seconds: 2));
      
      Pop.hideLoading();
      _updateResult('场景2: 成功 - async/await 中间调用 loading 正常');
      Pop.toast('场景2测试成功', toastType: ToastType.success);
    } catch (e) {
      _updateResult('场景2: 失败 - $e');
      Pop.toast('场景2测试失败: $e', toastType: ToastType.error);
    }
  }

  /// 场景3: Stream 监听中调用 loading
  void _testStream() {
    _updateResult('');
    try {
      final controller = StreamController<int>();
      final stream = controller.stream;

      stream.listen((data) {
        // 在 Stream 监听回调中调用 loading
        Pop.loading(message: '处理流数据: $data');
        Future.delayed(const Duration(seconds: 1)).then((_) {
          Pop.hideLoading();
          if (data == 2) {
            controller.close();
            _updateResult('场景3: 成功 - Stream 监听中调用 loading 正常');
            Pop.toast('场景3测试成功', toastType: ToastType.success);
          }
        });
      });

      // 发送数据
      Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (timer.tick <= 2) {
          controller.add(timer.tick);
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      _updateResult('场景3: 失败 - $e');
      Pop.toast('场景3测试失败: $e', toastType: ToastType.error);
    }
  }

  /// 场景4: Timer 回调中调用 loading
  void _testTimer() {
    _updateResult('');
    try {
      Timer(const Duration(milliseconds: 100), () {
        // 在 Timer 回调中调用 loading
        Pop.loading(message: '定时任务执行中...');
        Timer(const Duration(seconds: 2), () {
          Pop.hideLoading();
          _updateResult('场景4: 成功 - Timer 回调中调用 loading 正常');
          Pop.toast('场景4测试成功', toastType: ToastType.success);
        });
      });
    } catch (e) {
      _updateResult('场景4: 失败 - $e');
      Pop.toast('场景4测试失败: $e', toastType: ToastType.error);
    }
  }

  /// 场景5: postFrameCallback 中调用 loading（最关键的测试）
  void _testPostFrameCallback() {
    _updateResult('');
    try {
      // 在 postFrameCallback 中调用 loading
      // 这会在构建阶段之后立即执行，但可能仍在构建周期内
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 这里调用 loading，验证 SafeOverlayEntry 是否正常工作
        Pop.loading(message: 'postFrameCallback 中调用');
        Future.delayed(const Duration(seconds: 2)).then((_) {
          Pop.hideLoading();
          _updateResult('场景5: 成功 - postFrameCallback 中调用 loading 正常');
          Pop.toast('场景5测试成功（关键测试）', toastType: ToastType.success);
        });
      });
    } catch (e) {
      _updateResult('场景5: 失败 - $e');
      Pop.toast('场景5测试失败: $e', toastType: ToastType.error);
    }
  }

  /// 场景6: initState 中异步调用 loading
  void _testInitStateAsync() {
    _updateResult('');
    try {
      // 创建一个新的 StatefulWidget 来测试 initState
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const _TestInitStateWidget(),
        ),
      ).then((result) {
        if (result == true) {
          _updateResult('场景6: 成功 - initState 中异步调用 loading 正常');
          Pop.toast('场景6测试成功', toastType: ToastType.success);
        }
      });
    } catch (e) {
      _updateResult('场景6: 失败 - $e');
      Pop.toast('场景6测试失败: $e', toastType: ToastType.error);
    }
  }
}

/// 用于测试 initState 中异步调用 loading 的 Widget
class _TestInitStateWidget extends StatefulWidget {
  const _TestInitStateWidget();

  @override
  State<_TestInitStateWidget> createState() => _TestInitStateWidgetState();
}

class _TestInitStateWidgetState extends State<_TestInitStateWidget> {
  @override
  void initState() {
    super.initState();
    // 在 initState 中异步调用 loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Pop.loading(message: 'initState 异步加载中...');
      Future.delayed(const Duration(seconds: 2)).then((_) {
        Pop.hideLoading();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('initState 测试'),
      ),
      body: const Center(
        child: Text('这个页面在 initState 中异步调用了 loading'),
      ),
    );
  }
}

