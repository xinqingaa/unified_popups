import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';


class DatePage extends StatelessWidget {
  const DatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScopeWidget(
     child: Scaffold(
      appBar: AppBar(title: const Text('Date Birth Demo')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final result = await Pop.date(
                    initialDate: DateTime(2000, 6, 11), // 初始显示 2000-01-31
                  );
                  log("Confirm result: $result" , name: "DatePage" ,level: 800);
                },
                child: const Text('时间选择器: 默认配置 '),
              ),
              const SizedBox(height: 12,),
              ElevatedButton(
                onPressed: () async {
                  final result = await Pop.date(
                      initialDate: DateTime(2000, 6, 11), // 初始显示 2000-01-31
                      // minDate: DateTime(1999), // 可选：自定义最小年份
                      // maxDate: DateTime(2020), // 可选：自定义最大年份
                      headerBg: Colors.pink,
                      height: 120,
                      radius: 0
                  );
                  log("Confirm result: $result", name: "DatePage" , level: 900);
                },
                child: const Text('时间选择器: 无圆角、 定制高度和头部颜色'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final result = await Pop.date(
                    title: '选择入职日期',
                    initialDate: DateTime.now(),
                    minDate: DateTime(2020, 1, 1),
                    maxDate: DateTime.now(),
                    confirmText: '确定',
                    cancelText: '取消',
                    activeColor: Colors.green,
                    noActiveColor: Colors.grey,
                    headerBg: Colors.green,
                    height: 200,
                    radius: 16,
                  );
                  log("入职日期: $result", name: "DatePage", level: 800);
                },
                child: const Text('入职日期选择器'),
              ),
            ],
          ),
        ),
      ),
    )
    );
  }
}
