import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import 'app/shell.dart';
import 'app/theme.dart';

void main() {
  runApp(const FitPulseApp());
}

class FitPulseApp extends StatelessWidget {
  const FitPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitPulse',
      theme: buildFitPulseTheme(),
      navigatorObservers: [Pop.routeObserver],
      builder: Pop.hostBuilder,
      home: const FitPulseShell(),
    );
  }
}
