import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

class PopupManagerPage extends StatefulWidget {
  const PopupManagerPage({super.key});

  @override
  State<PopupManagerPage> createState() => _PopupManagerPageState();
}

class _PopupManagerPageState extends State<PopupManagerPage> {
  String? _currentPopupId;
  int _popupCount = 0;

  @override
  void initState() {
    super.initState();
    // 监听弹窗状态变化
    PopupManager.hasNonToastPopupNotifier.addListener(_onPopupStateChanged);
  }

  @override
  void dispose() {
    PopupManager.hasNonToastPopupNotifier.removeListener(_onPopupStateChanged);
    super.dispose();
  }

  void _onPopupStateChanged() {
    setState(() {
      // 更新弹窗计数
      _popupCount = PopupManager.hasNonToastPopupNotifier.value ? 1 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeWidget(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PopupManager 示例'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // 使用 PopupManager.maybePop 智能处理返回
              PopupManager.maybePop(context);
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 状态显示卡片
              Card(
                color: _popupCount > 0 ? Colors.orange.shade50 : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _popupCount > 0 ? Icons.warning : Icons.check_circle,
                            color: _popupCount > 0 ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _popupCount > 0 ? '有弹窗显示中' : '无弹窗',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _popupCount > 0 ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _popupCount > 0
                            ? 'PopScopeWidget 已拦截返回键，按返回键将关闭弹窗'
                            : 'PopScopeWidget 允许返回，按返回键将返回上一页',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // 基础示例
              _buildSection(
                title: '基础示例',
                children: [
                  ElevatedButton(
                    onPressed: _showBasicPopup,
                    child: const Text('显示基础弹窗'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _showCustomStyledPopup,
                    child: const Text('显示自定义样式弹窗'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _showPopupWithCallback,
                    child: const Text('显示带回调的弹窗'),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 弹窗管理示例
              _buildSection(
                title: '弹窗管理',
                children: [
                  ElevatedButton(
                    onPressed: _currentPopupId != null ? _hideCurrentPopup : null,
                    child: const Text('关闭当前弹窗（通过 ID）'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: PopupManager.hasNonToastPopup ? _hideLastPopup : null,
                    child: const Text('关闭最后一个弹窗'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: PopupManager.hasNonToastPopup ? _hideAllPopups : null,
                    child: const Text('关闭所有弹窗'),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 多弹窗示例
              _buildSection(
                title: '多弹窗层级',
                children: [
                  ElevatedButton(
                    onPressed: _showMultiplePopups,
                    child: const Text('显示多个弹窗（测试层级）'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _showNestedPopups,
                    child: const Text('显示嵌套弹窗'),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 返回键处理示例
              _buildSection(
                title: '返回键处理',
                children: [
                  const Text(
                    'PopScopeWidget 会自动处理返回键：',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• 有弹窗时：拦截返回键，关闭最上层弹窗'),
                  const Text('• 无弹窗时：允许返回，执行 Navigator.pop()'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('请按返回键测试 PopScopeWidget 的行为'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text('测试返回键行为'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  // 显示基础弹窗
  void _showBasicPopup() {
    _currentPopupId = PopupManager.show(
      PopupConfig(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info, size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                '基础弹窗',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('这是使用 PopupManager.show 创建的基础弹窗'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_currentPopupId != null) {
                    PopupManager.hide(_currentPopupId!);
                    _currentPopupId = null;
                  }
                },
                child: const Text('关闭'),
              ),
            ],
          ),
        ),
        position: PopupPosition.center,
        animation: PopupAnimation.fade,
        animationDuration: const Duration(milliseconds: 200),
        type: PopupType.other,
      ),
    );
  }

  // 显示自定义样式弹窗
  void _showCustomStyledPopup() {
    _currentPopupId = PopupManager.show(
      PopupConfig(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.purple, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                '自定义样式弹窗',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '支持完全自定义样式和内容',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () {
                  if (_currentPopupId != null) {
                    PopupManager.hide(_currentPopupId!);
                    _currentPopupId = null;
                  }
                },
                child: const Text('关闭'),
              ),
            ],
          ),
        ),
        position: PopupPosition.center,
        animation: PopupAnimation.fade,
        animationDuration: const Duration(milliseconds: 300),
        type: PopupType.other,
      ),
    );
  }

  // 显示带回调的弹窗
  void _showPopupWithCallback() {
    _currentPopupId = PopupManager.show(
      PopupConfig(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                '带回调的弹窗',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('关闭时会触发 onDismiss 回调'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_currentPopupId != null) {
                    PopupManager.hide(_currentPopupId!);
                    _currentPopupId = null;
                  }
                },
                child: const Text('关闭'),
              ),
            ],
          ),
        ),
        position: PopupPosition.center,
        animation: PopupAnimation.fade,
        animationDuration: const Duration(milliseconds: 200),
        type: PopupType.other,
        onShow: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('弹窗已显示（onShow 回调）')),
          );
        },
        onDismiss: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('弹窗已关闭（onDismiss 回调）')),
          );
          _currentPopupId = null;
        },
      ),
    );
  }

  // 关闭当前弹窗
  void _hideCurrentPopup() {
    if (_currentPopupId != null) {
      PopupManager.hide(_currentPopupId!);
      _currentPopupId = null;
    }
  }

  // 关闭最后一个弹窗
  void _hideLastPopup() {
    PopupManager.hideLastNonToast();
  }

  // 关闭所有弹窗
  void _hideAllPopups() {
    PopupManager.hideAll();
    _currentPopupId = null;
  }

  // 显示多个弹窗
  void _showMultiplePopups() {
    // 显示第一个弹窗
    PopupManager.show(
      PopupConfig(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '第一个弹窗',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('这是底层的弹窗'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // 显示第二个弹窗（在上层）
                  PopupManager.show(
                    PopupConfig(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange, width: 2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '第二个弹窗',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text('这是上层的弹窗，会覆盖第一个'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                PopupManager.hideLast();
                              },
                              child: const Text('关闭上层弹窗'),
                            ),
                          ],
                        ),
                      ),
                      position: PopupPosition.center,
                      animation: PopupAnimation.fade,
                      type: PopupType.other,
                    ),
                  );
                },
                child: const Text('显示第二个弹窗'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  PopupManager.hideAll();
                },
                child: const Text('关闭所有弹窗'),
              ),
            ],
          ),
        ),
        position: PopupPosition.center,
        animation: PopupAnimation.fade,
        type: PopupType.other,
      ),
    );
  }

  // 显示嵌套弹窗
  void _showNestedPopups() {
    PopupManager.show(
      PopupConfig(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '外层弹窗',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // 在内层弹窗中再显示一个弹窗
                  PopupManager.show(
                    PopupConfig(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '内层弹窗',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text('这是嵌套在最内层的弹窗'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                // 关闭最内层弹窗
                                PopupManager.hideLast();
                              },
                              child: const Text('关闭内层弹窗'),
                            ),
                          ],
                        ),
                      ),
                      position: PopupPosition.center,
                      animation: PopupAnimation.fade,
                      type: PopupType.other,
                    ),
                  );
                },
                child: const Text('显示内层弹窗'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  PopupManager.hideAll();
                },
                child: const Text('关闭所有弹窗'),
              ),
            ],
          ),
        ),
        position: PopupPosition.center,
        animation: PopupAnimation.fade,
        type: PopupType.other,
      ),
    );
  }
}

