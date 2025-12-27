import 'package:example/pages/date_page.dart';
import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';
import 'pages/anchored_page.dart';
import 'pages/async_page.dart';
import 'pages/dialog_page.dart';
import 'pages/home_page.dart';
import 'pages/loading_page.dart';
import 'pages/popup_manager_page.dart';
import 'pages/sheet_page.dart';
import 'pages/toast_page.dart';


// 创建 GlobalKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
  // 确保 MaterialApp 构建完毕后，再初始化 PopupManager
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PopupManager.initialize(navigatorKey: navigatorKey);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 赋值给 navigatorKey
      navigatorKey: navigatorKey,
      title: 'Unified Popup Example',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      navigatorObservers: [PopupRouteObserver()], // 路由观察者 ,  sheet 、confirm 等弹窗会根据路由变化自动关闭
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/toast': (context) => const ToastPage(),
        '/dialog': (context) => const DialogPage(),
        '/loading': (context) => const LoadingPage(),
        '/sheet': (context) => const SheetPage(),
        '/anchored': (context) => const AnchoredPage(),
        '/date': (context) => const DatePage(),
        '/async': (context) => const AsyncPage(),
        '/popup_manager': (context) => const PopupManagerPage(),
      },
    );
  }
}
