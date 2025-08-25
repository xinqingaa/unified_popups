# 最佳实践指南

## 目录

- [设计原则](#设计原则)
- [使用建议](#使用建议)
- [性能优化](#性能优化)
- [常见问题](#常见问题)
- [代码示例](#代码示例)

## 设计原则

### 1. 一致性原则

保持弹窗样式和交互的一致性，提升用户体验：

```dart
// 推荐：使用统一的样式配置
class AppTheme {
  static const Color primaryColor = Colors.blue;
  static const Color dangerColor = Colors.red;
  static const double borderRadius = 12.0;
  
  static BoxDecoration get dialogDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  );
}

// 在弹窗中使用统一样式
Pop.confirm(
  title: '确认操作',
  content: '是否继续？',
  decoration: AppTheme.dialogDecoration,
  confirmBgColor: AppTheme.primaryColor,
);
```

### 2. 可访问性原则

确保弹窗对所有用户都是可访问的：

```dart
// 推荐：提供语义化的标签
Pop.confirm(
  title: '删除确认',
  content: '此操作不可撤销，请确认是否删除？',
  confirmText: '删除',
  cancelText: '取消',
  // 使用语义化的按钮文本
);
```

### 3. 响应式原则

确保弹窗在不同屏幕尺寸下都能正常显示：

```dart
// 推荐：使用相对尺寸
await Pop.sheet(
  maxWidth: SheetDimension.fraction(0.9), // 90% 屏幕宽度
  maxHeight: SheetDimension.fraction(0.8), // 80% 屏幕高度
  childBuilder: (dismiss) => ResponsiveContent(),
);
```

## 使用建议

### 1. Toast 使用建议

```dart
// ✅ 推荐：简洁明了
Pop.toast('保存成功', toastType: ToastType.success);

// ✅ 推荐：重要信息使用遮罩
Pop.toast(
  '网络连接已断开',
  showBarrier: true,
  barrierDismissible: true,
  duration: Duration(seconds: 3),
);

// ❌ 避免：过于复杂的 Toast
Pop.toast(
  '这是一个非常长的消息，包含了太多信息，用户可能无法快速理解...',
  decoration: ComplexDecoration(),
  style: ComplexTextStyle(),
);
```

### 2. Loading 使用建议

```dart
// ✅ 推荐：为异步操作提供反馈
Future<void> submitForm() async {
  final loadingId = Pop.loading(message: '提交中...');
  
  try {
    await api.submit(formData);
    Pop.hideLoading(loadingId);
    Pop.toast('提交成功', toastType: ToastType.success);
  } catch (e) {
    Pop.hideLoading(loadingId);
    Pop.toast('提交失败: $e', toastType: ToastType.error);
  }
}

// ✅ 推荐：长时间操作提供进度信息
Future<void> uploadFile() async {
  final loadingId = Pop.loading(message: '上传中...');
  
  try {
    await uploadWithProgress((progress) {
      // 可以更新 loading 消息显示进度
      Pop.hideLoading(loadingId);
      Pop.loading(message: '上传中... ${(progress * 100).toInt()}%');
    });
    Pop.hideLoading(loadingId);
    Pop.toast('上传成功', toastType: ToastType.success);
  } catch (e) {
    Pop.hideLoading(loadingId);
    Pop.toast('上传失败', toastType: ToastType.error);
  }
}
```

### 3. Confirm 使用建议

```dart
// ✅ 推荐：明确的操作描述
final result = await Pop.confirm(
  title: '删除用户',
  content: '删除用户 "张三" 后，该用户的所有数据将被永久删除且无法恢复。',
  confirmText: '删除用户',
  cancelText: '取消',
  confirmBgColor: Colors.red,
);

// ✅ 推荐：使用 confirmChild 添加输入框
final result = await Pop.confirm(
  title: '输入验证码',
  content: '请输入收到的验证码：',
  confirmChild: TextField(
    decoration: InputDecoration(
      labelText: '验证码',
      border: OutlineInputBorder(),
    ),
    keyboardType: TextInputType.number,
  ),
);

// ✅ 推荐：危险操作使用特殊样式
final result = await Pop.confirm(
  title: '危险操作',
  content: '此操作不可撤销！',
  confirmText: '确认删除',
  confirmBgColor: Colors.red,
  buttonLayout: ConfirmButtonLayout.column,
  showCloseButton: true,
);
```

### 4. Sheet 使用建议

```dart
// ✅ 推荐：使用 ListView 处理长内容
await Pop.sheet(
  title: '选择城市',
  childBuilder: (dismiss) => ListView.builder(
    itemCount: cities.length,
    itemBuilder: (context, index) => ListTile(
      title: Text(cities[index].name),
      onTap: () => dismiss(cities[index]),
    ),
  ),
);

// ✅ 推荐：表单使用 Column + SingleChildScrollView
await Pop.sheet(
  title: '用户信息',
  childBuilder: (dismiss) => SingleChildScrollView(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(decoration: InputDecoration(labelText: '姓名')),
          TextField(decoration: InputDecoration(labelText: '邮箱')),
          TextField(decoration: InputDecoration(labelText: '电话')),
          ElevatedButton(
            onPressed: () => dismiss(),
            child: Text('提交'),
          ),
        ],
      ),
    ),
  ),
);

// ✅ 推荐：使用自定义样式提升体验
await Pop.sheet(
  title: '操作成功',
  backgroundColor: Colors.grey[50],
  borderRadius: BorderRadius.circular(20),
  childBuilder: (dismiss) => Container(
    padding: EdgeInsets.all(24),
    child: Column(
      children: [
        Icon(Icons.check_circle, color: Colors.green, size: 64),
        SizedBox(height: 16),
        Text('操作已完成', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('您的操作已成功处理'),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => dismiss(),
          child: Text('确定'),
        ),
      ],
    ),
  ),
);
```

### 5. Date 使用建议

```dart
// ✅ 推荐：提供合理的日期范围
final date = await Pop.date(
  title: '选择生日',
  initialDate: DateTime(1990, 1, 1),
  minDate: DateTime(1900, 1, 1),
  maxDate: DateTime.now(),
);

// ✅ 推荐：使用语义化的标题
final date = await Pop.date(
  title: '选择入职日期',
  initialDate: DateTime.now(),
  minDate: DateTime(2020, 1, 1),
  maxDate: DateTime.now(),
  confirmText: '确定',
  cancelText: '取消',
);
```

### 6. Menu 使用建议

```dart
// ✅ 推荐：使用图标增强可读性
final result = await Pop.menu<String>(
  anchorKey: buttonKey,
  builder: (dismiss) => Column(
    children: [
      ListTile(
        leading: Icon(Icons.copy),
        title: Text('复制'),
        onTap: () => dismiss('copy'),
      ),
      ListTile(
        leading: Icon(Icons.edit),
        title: Text('编辑'),
        onTap: () => dismiss('edit'),
      ),
      ListTile(
        leading: Icon(Icons.delete, color: Colors.red),
        title: Text('删除', style: TextStyle(color: Colors.red)),
        onTap: () => dismiss('delete'),
      ),
    ],
  ),
);

// ✅ 推荐：提供操作说明
final result = await Pop.menu<String>(
  anchorKey: buttonKey,
  builder: (dismiss) => Column(
    children: [
      _buildMenuItem(
        icon: Icons.share,
        title: '分享',
        subtitle: '分享到社交媒体',
        onTap: () => dismiss('share'),
      ),
      _buildMenuItem(
        icon: Icons.favorite,
        title: '收藏',
        subtitle: '添加到收藏夹',
        onTap: () => dismiss('favorite'),
      ),
    ],
  ),
);
```

## 性能优化

### 1. 避免频繁创建弹窗

```dart
// ❌ 避免：频繁创建相同弹窗
for (int i = 0; i < 100; i++) {
  Pop.toast('消息 $i');
}

// ✅ 推荐：使用节流
Timer? _toastTimer;
void showToast(String message) {
  _toastTimer?.cancel();
  _toastTimer = Timer(Duration(milliseconds: 100), () {
    Pop.toast(message);
  });
}

// ✅ 推荐：批量处理
void showBatchToasts(List<String> messages) {
  for (int i = 0; i < messages.length; i++) {
    Timer(Duration(milliseconds: i * 200), () {
      Pop.toast(messages[i]);
    });
  }
}
```

### 2. 合理使用 Loading

```dart
// ✅ 推荐：为长时间操作显示 Loading
Future<void> longOperation() async {
  final loadingId = Pop.loading(message: '处理中...');
  
  try {
    await Future.delayed(Duration(seconds: 3)); // 模拟长时间操作
    Pop.hideLoading(loadingId);
    Pop.toast('操作完成', toastType: ToastType.success);
  } catch (e) {
    Pop.hideLoading(loadingId);
    Pop.toast('操作失败', toastType: ToastType.error);
  }
}

// ❌ 避免：为快速操作显示 Loading
Future<void> quickOperation() async {
  final loadingId = Pop.loading(message: '处理中...'); // 不必要的 Loading
  await Future.delayed(Duration(milliseconds: 100)); // 快速操作
  Pop.hideLoading(loadingId);
}
```

### 3. 优化列表性能

```dart
// ✅ 推荐：使用 ListView.builder 处理大量数据
await Pop.sheet(
  childBuilder: (dismiss) => ListView.builder(
    itemCount: 1000,
    itemBuilder: (context, index) => ListTile(
      title: Text('项目 $index'),
      onTap: () => dismiss('item_$index'),
    ),
  ),
);

// ✅ 推荐：使用 const 构造函数
await Pop.sheet(
  childBuilder: (dismiss) => ListView(
    children: const [
      ListTile(title: Text('选项 1')),
      ListTile(title: Text('选项 2')),
      ListTile(title: Text('选项 3')),
    ],
  ),
);
```

## 常见问题

### 1. 键盘弹出问题

**问题：** 键盘弹出时弹窗被遮挡

**解决方案：**

```dart
// ✅ 推荐：使用 confirmChild 添加输入框
Pop.confirm(
  title: '输入信息',
  content: '请填写以下信息：',
  confirmChild: Column(
    children: [
      TextField(decoration: InputDecoration(labelText: '姓名')),
      TextField(decoration: InputDecoration(labelText: '邮箱')),
    ],
  ),
);

// ✅ 推荐：在 Sheet 中使用 ListView
Pop.sheet(
  childBuilder: (dismiss) => ListView(
    children: [
      TextField(decoration: InputDecoration(labelText: '字段1')),
      TextField(decoration: InputDecoration(labelText: '字段2')),
    ],
  ),
);
```

### 2. 返回键处理

**问题：** 弹窗显示时按返回键没有关闭弹窗

**解决方案：**

```dart
// ✅ 推荐：使用 PopScopeWidget
MaterialApp(
  home: PopScopeWidget(
    child: HomePage(),
  ),
);

// ✅ 推荐：手动处理返回键
WillPopScope(
  onWillPop: () async {
    if (PopupManager.hasNonToastPopup) {
      PopupManager.hideLastNonToast();
      return false;
    }
    return true;
  },
  child: HomePage(),
);
```

### 3. 弹窗重叠问题

**问题：** 多个弹窗同时显示造成重叠

**解决方案：**

```dart
// ✅ 推荐：使用全局管理
class PopupService {
  static String? _currentLoadingId;
  
  static void showLoading(String message) {
    hideLoading(); // 先隐藏之前的 Loading
    _currentLoadingId = Pop.loading(message: message);
  }
  
  static void hideLoading() {
    if (_currentLoadingId != null) {
      Pop.hideLoading(_currentLoadingId!);
      _currentLoadingId = null;
    }
  }
}

// 使用
PopupService.showLoading('加载中...');
await someOperation();
PopupService.hideLoading();
```

### 4. popupId 使用问题

**问题：** 不清楚哪些弹窗可以通过 popupId 关闭

**解决方案：**

```dart
// ✅ 正确：Loading 弹窗可以通过 popupId 关闭
final loadingId = Pop.loading(message: '加载中...');
// ... 异步操作
Pop.hideLoading(loadingId); // 可以关闭

// ❌ 错误：Toast 弹窗不能通过 popupId 关闭
Pop.toast('消息'); // 不返回 popupId，无法手动关闭

// ❌ 错误：Confirm 弹窗不能通过 popupId 关闭
await Pop.confirm(content: '确认？'); // 通过用户交互关闭

// ✅ 正确：使用全局管理方法
PopupManager.hideLast(); // 隐藏最后一个弹窗
PopupManager.hideAll(); // 隐藏所有弹窗
PopupManager.hideLastNonToast(); // 隐藏最后一个非 Toast 弹窗
```

### 5. 弹窗生命周期管理

**问题：** 弹窗在页面销毁时没有正确清理

**解决方案：**

```dart
class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String? _loadingId;
  
  @override
  void dispose() {
    // 页面销毁时清理弹窗
    if (_loadingId != null) {
      Pop.hideLoading(_loadingId!);
    }
    super.dispose();
  }
  
  Future<void> _performOperation() async {
    _loadingId = Pop.loading(message: '处理中...');
    try {
      await someAsyncOperation();
      Pop.hideLoading(_loadingId!);
      _loadingId = null;
    } catch (e) {
      if (_loadingId != null) {
        Pop.hideLoading(_loadingId!);
        _loadingId = null;
      }
      Pop.toast('操作失败', toastType: ToastType.error);
    }
  }
}

### 4. 样式不一致问题

**问题：** 不同页面的弹窗样式不一致

**解决方案：**

```dart
// ✅ 推荐：创建统一的样式配置
class PopupStyles {
  static const Color primaryColor = Colors.blue;
  static const Color dangerColor = Colors.red;
  static const double borderRadius = 12.0;
  
  static BoxDecoration get dialogDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  );
  
  static TextStyle get titleStyle => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  
  static TextStyle get contentStyle => TextStyle(
    fontSize: 14,
    color: Colors.black54,
  );
}

// 在弹窗中使用
Pop.confirm(
  title: '确认操作',
  content: '是否继续？',
  decoration: PopupStyles.dialogDecoration,
  titleStyle: PopupStyles.titleStyle,
  contentStyle: PopupStyles.contentStyle,
  confirmBgColor: PopupStyles.primaryColor,
);
```

## 代码示例

### 完整的表单提交流程

```dart
class FormService {
  static Future<bool> submitForm(Map<String, dynamic> formData) async {
    // 1. 显示加载状态
    final loadingId = Pop.loading(message: '提交中...');
    
    try {
      // 2. 执行提交操作
      await api.submit(formData);
      
      // 3. 隐藏加载状态
      Pop.hideLoading(loadingId);
      
      // 4. 显示成功提示
      Pop.toast('提交成功', toastType: ToastType.success);
      
      return true;
    } catch (e) {
      // 5. 隐藏加载状态
      Pop.hideLoading(loadingId);
      
      // 6. 显示错误提示
      Pop.toast('提交失败: $e', toastType: ToastType.error);
      
      return false;
    }
  }
  
  static Future<bool> confirmSubmit(Map<String, dynamic> formData) async {
    // 1. 显示确认对话框
    final confirmed = await Pop.confirm(
      title: '确认提交',
      content: '请确认以下信息无误：',
      confirmChild: _buildFormSummary(formData),
      confirmText: '确认提交',
      cancelText: '返回修改',
    );
    
    if (confirmed == true) {
      // 2. 执行提交
      return await submitForm(formData);
    }
    
    return false;
  }
  
  static Widget _buildFormSummary(Map<String, dynamic> formData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('姓名: ${formData['name']}'),
        Text('邮箱: ${formData['email']}'),
        Text('电话: ${formData['phone']}'),
      ],
    );
  }
}
```

### 列表选择组件

```dart
class ListSelector {
  static Future<T?> selectFromList<T>({
    required String title,
    required List<T> items,
    required String Function(T item) itemTitle,
    String? Function(T item)? itemSubtitle,
    Widget? Function(T item)? itemLeading,
    Widget? Function(T item)? itemTrailing,
  }) async {
    return await Pop.sheet<T>(
      title: title,
      childBuilder: (dismiss) => ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: itemLeading?.call(item),
            title: Text(itemTitle(item)),
            subtitle: itemSubtitle?.call(item) != null 
              ? Text(itemSubtitle!(item)!) 
              : null,
            trailing: itemTrailing?.call(item),
            onTap: () => dismiss(item),
          );
        },
      ),
    );
  }
}

// 使用示例
final selectedCity = await ListSelector.selectFromList<City>(
  title: '选择城市',
  items: cities,
  itemTitle: (city) => city.name,
  itemSubtitle: (city) => city.province,
  itemLeading: (city) => Icon(Icons.location_city),
);
```

### 错误处理工具

```dart
class ErrorHandler {
  static void showError(String message, {String? title}) {
    Pop.toast(message, toastType: ToastType.error);
  }
  
  static void showNetworkError() {
    Pop.toast(
      '网络连接异常，请检查网络设置',
      toastType: ToastType.error,
      duration: Duration(seconds: 3),
    );
  }
  
  static Future<bool> confirmDangerousAction(String action) async {
    final result = await Pop.confirm(
      title: '危险操作',
      content: '此操作不可撤销，请确认是否继续？',
      confirmText: action,
      confirmBgColor: Colors.red,
      buttonLayout: ConfirmButtonLayout.column,
      showCloseButton: true,
    );
    
    return result == true;
  }
  
  static void showRetryDialog(String message, VoidCallback onRetry) async {
    final result = await Pop.confirm(
      title: '操作失败',
      content: message,
      confirmText: '重试',
      cancelText: '取消',
      confirmBgColor: Colors.blue,
    );
    
    if (result == true) {
      onRetry();
    }
  }
}
```

这些最佳实践将帮助你更好地使用 Unified Popups 库，提升用户体验和代码质量。
