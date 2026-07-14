import 'package:flutter/material.dart';

import 'lab_shell.dart';

/// Legacy route name: forwards to [LabShell].
class LabPage extends StatelessWidget {
  const LabPage({super.key});

  @override
  Widget build(BuildContext context) => const LabShell();
}
