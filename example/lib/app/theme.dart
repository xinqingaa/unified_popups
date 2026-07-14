import 'package:flutter/material.dart';

/// FitPulse Material 3 theme：单一 seed，角色色驱动，少硬编码。
ThemeData buildFitPulseTheme() {
  const seed = Color(0xFF0D9488);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: scheme.surfaceTint,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.secondaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
        );
      }),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      dragHandleColor: scheme.onSurfaceVariant,
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.surfaceTint,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.secondaryContainer,
      labelStyle: TextStyle(color: scheme.onSecondaryContainer),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: shape,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: shape,
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.outline),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 40),
        foregroundColor: scheme.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 14,
        height: 1.35,
        color: scheme.onSurfaceVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      space: 1,
      thickness: 1,
    ),
  );
}
