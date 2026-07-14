import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import 'app/shell.dart';
import 'app/theme.dart';
import 'features/lab/lab_shell.dart';

void main() {
  runApp(const FitPulseApp());
}

class FitPulseApp extends StatelessWidget {
  const FitPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'unified_popups Example',
      theme: buildFitPulseTheme(),
      navigatorObservers: [Pop.routeObserver],
      builder: Pop.hostBuilder,
      home: const ExampleHomePage(),
    );
  }
}

/// Dual entry: product demo vs API showcase.
class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          children: [
            Text(
              'unified_popups',
              style: text.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '选择入口：真实 App 看用法，API 展柜按能力验收。',
              style: text.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    leading: Icon(
                      Icons.fitness_center_outlined,
                      color: scheme.primary,
                    ),
                    title: const Text('FitPulse 真实 App'),
                    subtitle: const Text(
                      '今日 / 训练 / 数据 / 我的 · Sheet、Flow、Menu 真实动机',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const FitPulseShell(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    leading: Icon(
                      Icons.science_outlined,
                      color: scheme.primary,
                    ),
                    title: const Text('API 展柜'),
                    subtitle: const Text(
                      'Toast → Loading → Sheet → Flow · 右上角 Entry 计数',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LabShell(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
