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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'unified_popups',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '选择入口：真实 App 看用法，API 展柜按能力逐项验收。',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
              const Spacer(),
              _EntryCard(
                icon: Icons.fitness_center,
                title: 'FitPulse 真实 App',
                subtitle: '四个业务 Tab：同步、训练 Flow、Sheet/Menu、档案等真实动机触发。',
                color: scheme.primaryContainer,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const FitPulseShell(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _EntryCard(
                icon: Icons.science_outlined,
                title: 'API 展柜',
                subtitle: '按类型分页：Toast → Loading → … → 通用 Config → 异步边界。'
                    '右上角常驻 Entry 计数。',
                color: scheme.secondaryContainer,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LabShell(),
                    ),
                  );
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(height: 1.35)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
