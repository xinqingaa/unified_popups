import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';
import 'dart:developer';

class DatePage extends StatelessWidget {
  const DatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    // minDate: DateTime(1980), // 可选：自定义最小年份
                    // maxDate: DateTime(2025), // 可选：自定义最大年份
                    headerBg: Colors.blue,
                    height: 120
                  );
                  log("Processing data: $result", name: "MyAwesomeFunction"); // 带命名的日志
                },
                child: const Text('时间选择器 - 定制高度和头部颜色 '),
              ),
              const SizedBox(height: 12,),
              ElevatedButton(
                onPressed: () async {
                  final result = await Pop.date(
                      initialDate: DateTime(2000, 6, 11), // 初始显示 2000-01-31
                      // minDate: DateTime(1980), // 可选：自定义最小年份
                      // maxDate: DateTime(2025), // 可选：自定义最大年份
                  );
                  print('Confirm result: $result');
                },
                child: const Text('时间选择器 - 默认高度和颜色 '),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
