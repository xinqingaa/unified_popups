import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

import 'app/shell.dart';
import 'app/theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const FitPulseApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PopupManager.initialize(navigatorKey: navigatorKey);
  });
}

class FitPulseApp extends StatelessWidget {
  const FitPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'FitPulse',
      theme: buildFitPulseTheme(),
      navigatorObservers: [PopupRouteObserver()],
      builder: (context, child) => PopScopeWidget(
        child: child ?? const SizedBox.shrink(),
      ),
      home: const FitPulseShell(),
    );
  }
}
