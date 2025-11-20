import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

class SheetPage extends StatelessWidget {
  const SheetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: PopScopeWidget(
        child: Scaffold(
          appBar: AppBar(title: const Text('Sheet & Drawer Demo')),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // 输入框
              const TextField(
                decoration: InputDecoration(
                  labelText: '请输入',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showBottomSheet,
                child: const Text('Show Bottom Sheet'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showLeftDrawer,
                child: const Text('Show Left Drawer'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showRightDrawer,
                child: const Text('Show Right Drawer'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed:_showTopNotification,
                child: const Text('Show Top Notification'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showBottomMenu,
                child: const Text('长列表 Bottom Sheet'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showShort,
                child: const Text('短列表'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showFullScreenBottomDrawer,
                child: const Text('全屏底部抽屉'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showBottomSheetWithInputNoAvoid,
                child: const Text('Bottom Sheet 含输入框'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showBottomSheetWithForm,
                child: const Text('表单 Sheet'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showBottomSheetWithCustomStyle,
                child: const Text('自定义样式 Sheet'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showAnchoredBottomSheet,
                child: const Text('TabBar 顶部 Sheet'),
              ),
            ],
              ),
            ),
          ),
          bottomNavigationBar: Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 4,
            child: const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(icon: Icon(Icons.home), text: '首页'),
                Tab(icon: Icon(Icons.list), text: '列表'),
                Tab(icon: Icon(Icons.settings), text: '设置'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBottomSheet() async {
    final result = await Pop.sheet<String>(
      title: '选择操作',
      useSafeArea: true,
      showBarrier: false,
      showCloseButton: true,
      childBuilder: (dismiss) => ListView(
        shrinkWrap: true,
        children: [
          _buildItem(
            onTap: () => dismiss('share'),
            title: "分享"
          ),
          _buildItem(
              onTap: () => dismiss('edit'),
              title: "编辑"
          ),
          _buildItem(
              onTap: () => dismiss('delete'),
              title: "删除"
          ),
          _buildItem(
              onTap: () => dismiss(),
              title: "关闭"
          ),
        ],
      ),
    );
    _handleSheetResult(result);
  }

  Widget _buildItem({required VoidCallback onTap , required String title}){
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10 , horizontal: 0),
        child: Row(
          children: [
            Text(title)
          ],
        ),
      ),
    );
  }

  void _showLeftDrawer() async {
    final result = await Pop.sheet<String>(
      direction: SheetDirection.left,
      showCloseButton: true,
      maxWidth: const SheetDimension.fraction(0.75),
      title: '菜单',
      childBuilder: (dismiss) => ListView(
        children: [
          ListTile(leading: const Icon(Icons.home), title: const Text('首页'), onTap: () => dismiss('home')),
          ListTile(leading: const Icon(Icons.settings), title: const Text('设置'), onTap: () => dismiss('setting')),
        ],
      ),
    );
    _handleSheetResult(result);
  }

  void _showRightDrawer() async {
    final result = await Pop.sheet<String>(
      direction: SheetDirection.right,
      showCloseButton: true,
      maxWidth: const SheetDimension.fraction(0.75),
      title: '菜单',
      childBuilder: (dismiss) => Column(
        children: [
          ListTile(leading: const Icon(Icons.abc), title: const Text('abc'), onTap: () => dismiss('abc')),
          ListTile(leading: const Icon(Icons.vaccines), title: const Text('vaccines'), onTap: () => dismiss('vaccines')),
        ],
      ),
    );
    _handleSheetResult(result);
  }

  void _showTopNotification() {
    Pop.sheet(
      direction: SheetDirection.top,
      showCloseButton: true,
      title: '新消息',
      backgroundColor: Colors.amber.shade100,
      childBuilder: (dismiss) => ListTile(
        title: const Text('您的快递已到达'),
        subtitle: const Text('点击查看详情'),
        onTap: () => dismiss(),
      ),
    );
  }


  void _showBottomMenu() async {
    final result = await Pop.sheet<String>(
      title: '选择一个水果 可滚动',
      direction: SheetDirection.bottom,
      imgPath: "assets/temp.png",
      maxHeight: const SheetDimension.pixel(400),
      childBuilder: (dismiss) => ListView.builder(
        itemCount: 20, // 很多项，以确保内容会滚动
        itemBuilder: (context, index) {
          final fruit = '水果 ${index + 1}';
          return ListTile(
            title: Text(fruit),
            onTap: () => dismiss(fruit),
          );
        },
      ),
    );
    _handleSheetResult(result);
  }

  void _showFullScreenBottomDrawer() {
    Pop.sheet(
      title: '全屏内容',
      height: const SheetDimension.fraction(1),
      useSafeArea: true,
      childBuilder: (dismiss) => Container(
        color: Colors.blue.shade50,
        child: Center(
          child: TextButton(
            onPressed: () => dismiss(),
            child: const Text('返回'),
          ),
        ),
      ),
    );
  }

  void _showShort(){
    Pop.sheet(
      title: '短列表',
      // maxHeight: const SheetDimension.fraction(0.6), // 最大占屏 60%
      childBuilder: (dismiss) => ListView(
        shrinkWrap: true,
        children: const [
          ListTile(title: Text('选项 1')),
          ListTile(title: Text('选项 2')),
        ],
      ),
    );
  }

    void _showBottomSheetWithInputNoAvoid() async {
    await Pop.sheet<void>(
      title: '填写信息',
      // 不做任何 viewInsets 处理，演示遮挡问题
      childBuilder: (dismiss) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: '昵称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => dismiss(),
                    child: const Text('提交'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleSheetResult(String? result) {
    print("result: $result");
  }

  void _showAnchoredBottomSheet() async {
    final result = await Pop.sheet<String>(
      title: 'TabBar 顶部弹出',
      direction: SheetDirection.bottom,
      
      dockToEdge: true,
      // edgeGap: ,
      showBarrier: true,
      childBuilder: (dismiss) => ListView(
        shrinkWrap: true,
        children: [
          _buildItem(onTap: () => dismiss('pay'), title: "支付"),
          _buildItem(onTap: () => dismiss('share'), title: "分享"),
          _buildItem(onTap: () => dismiss(), title: "关闭"),
        ],
      ),
    );
    _handleSheetResult(result);
  }

  void _showBottomSheetWithForm() async {
    await Pop.sheet<void>(
      title: '用户信息表单',
      childBuilder: (dismiss) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: '姓名',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: '邮箱',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: '手机号',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => dismiss(),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => dismiss(),
                    child: const Text('提交'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomSheetWithCustomStyle() async {
    await Pop.sheet<void>(
      title: '自定义样式',
      backgroundColor: Colors.grey[100],
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(10),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
      childBuilder: (dismiss) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 48),
                  SizedBox(height: 12),
                  Text(
                    '操作成功',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '您的操作已完成',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => dismiss(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('确定'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
