import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';

/// Shared building blocks for Lab pages.
class LabBanner extends StatelessWidget {
  const LabBanner({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: const TextStyle(height: 1.4)),
      ),
    );
  }
}

class LabGroup extends StatelessWidget {
  const LabGroup({
    required this.title,
    required this.children,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: 8),
        ...children.map(
          (child) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: child,
          ),
        ),
      ],
    );
  }
}

class LabAction extends StatelessWidget {
  const LabAction({
    required this.label,
    required this.onPressed,
    this.subtitle,
    this.tonal = false,
    this.outlined = false,
    super.key,
  });

  final String label;
  final String? subtitle;
  final VoidCallback? onPressed;
  final bool tonal;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final button = outlined
        ? OutlinedButton(
            onPressed: onPressed,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _Label(label: label, subtitle: subtitle),
            ),
          )
        : tonal
            ? FilledButton.tonal(
                onPressed: onPressed,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _Label(label: label, subtitle: subtitle),
                ),
              )
            : FilledButton(
                onPressed: onPressed,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _Label(label: label, subtitle: subtitle),
                ),
              );
    return SizedBox(width: double.infinity, child: button);
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.label, this.subtitle});

  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    if (subtitle == null) return Text(label);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        Text(
          subtitle!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

/// Sticky badge for AppBar — stays visible while Lab pages scroll.
class LabEntryBadge extends StatelessWidget {
  const LabEntryBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Pop.runtime.controller,
      builder: (context, _) {
        final entries = Pop.runtime.controller.entries;
        final active = entries
            .where((e) => e.state.isActive || e.state.isMounted)
            .length;
        final queued =
            entries.where((e) => e.state == PopupEntryState.queued).length;
        final label = queued > 0 ? '$active+$queued' : '$active';
        return Tooltip(
          message: '活跃/挂载 Entry：$active'
              '${queued > 0 ? ' · 排队 $queued' : ''}',
          child: Chip(
            visualDensity: VisualDensity.compact,
            label: Text('Entry $label'),
            avatar: Icon(
              Icons.layers_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        );
      },
    );
  }
}

/// Optional in-page status (notes). Prefer [LabEntryBadge] in AppBar for counts.
class LabStatusBar extends StatelessWidget {
  const LabStatusBar({super.key, this.extra});

  final String? extra;

  @override
  Widget build(BuildContext context) {
    if (extra == null || extra!.isEmpty) return const SizedBox.shrink();
    return LabBanner(text: extra!);
  }
}

class LabNote extends StatelessWidget {
  const LabNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
      ),
    );
  }
}

void labShowResult(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ),
  );
}

Future<void> labPush(BuildContext context, Widget page) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => page),
  );
}
