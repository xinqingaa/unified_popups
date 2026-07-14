import 'package:flutter/material.dart';

import '../features/home/home_tab.dart';
import '../features/lab/lab_shell.dart';
import '../features/profile/profile_tab.dart';
import '../features/progress/progress_tab.dart';
import '../features/workouts/workouts_tab.dart';
import 'fit_pulse_metrics.dart';

/// FitPulse 主壳：4 个业务 Tab。API 展柜从启动页或 AppBar 进入。
class FitPulseShell extends StatefulWidget {
  const FitPulseShell({super.key});

  @override
  State<FitPulseShell> createState() => _FitPulseShellState();
}

class _FitPulseShellState extends State<FitPulseShell> {
  int _index = 0;

  static const _titles = ['今日', '训练', '数据', '我的'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FitPulse · ${_titles[_index]}'),
        actions: [
          PopupMenuButton<String>(
            tooltip: '更多',
            onSelected: (value) {
              if (value == 'lab') {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LabShell(),
                  ),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'lab',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.science_outlined),
                  title: Text('打开 API 展柜'),
                  subtitle: Text('逐项验收弹窗能力'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          HomeTab(),
          WorkoutsTab(),
          ProgressTab(),
          ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: FitPulseMetrics.navigationBarHeight,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '今日',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: '训练',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: '数据',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
