import 'package:flutter/material.dart';
import 'package:omni_calendar_view/omni_calendar_view.dart';
import 'package:unified_popups/unified_popups.dart';

import 'calendar_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final OmniCalendarController controller;

  // 用于演示外部控制的状态变量
  final bool showLunar = false;
  final bool showSurroundingDays = true;
  late Locale locale = const Locale('en', 'EN');


  @override
  void initState() {
    super.initState();
    // 初始化控制器，可以传入初始日期
    controller = OmniCalendarController(
      initialDate: DateTime.now(),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _changeLocale(){
    if(locale == const Locale('en', 'EN')){
      setState(() {
        locale = const Locale('zh', 'CN');
      });
    }else{
      setState(() {
        locale = const Locale('en', 'EN');
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("弹框日历 demo"),
      ),
      body:SafeArea(
        child: ElevatedButton(
          onPressed:() {
            PopupManager.show(
              PopupConfig(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  margin: EdgeInsets.symmetric(horizontal: 12),
                  child: CalendarView(
                    controller: controller,
                    showLunar: showLunar,
                    locale: locale,
                    showSurroundingDays: showSurroundingDays
                  ),
                )
              )
            );
          },
          child: const Text('展示日历'),
        ),
      ),
    );
  }
}
