import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const primaryAccent = Color(0xFFFF6B2C);
  static const secondaryAccent = Color(0xFF8B9DFF);
  static const successAccent = Color(0xFF7FD17E);

  static const darkBackground = Color(0xFF0B0C0F);
  static const darkSurface = Color(0xFF12141A);
  static const darkSurfaceContainer = Color(0xFF1A1D24);
  static const darkSurfaceContainerHigh = Color(0xFF22262F);
  static const darkOutline = Color(0xFF2C313C);
  static const darkOnSurface = Color(0xFFE6E8EE);
  static const darkOnSurfaceVariant = Color(0xFFA8AFBF);
  static const darkError = Color(0xFFFF5A5A);

  static const lightBackground = Color(0xFFF4F5F8);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceContainer = Color(0xFFF0F2F7);
  static const lightSurfaceContainerHigh = Color(0xFFE5E8EF);
  static const lightOutline = Color(0xFFD4D8E0);
  static const lightOnSurface = Color(0xFF16181D);
  static const lightOnSurfaceVariant = Color(0xFF5F6675);
  static const lightError = Color(0xFFD93C3C);

  static const energyOrange = primaryAccent;
  static const pulseLime = successAccent;
  static const recoveryBlue = secondaryAccent;

  static const radiusSmall = 14.0;
  static const radiusMedium = 20.0;
  static const radiusLarge = 28.0;

  static ThemeData light() {
    final colorScheme =
        const ColorScheme(
          brightness: Brightness.light,
          primary: primaryAccent,
          onPrimary: Color(0xFF2A1208),
          primaryContainer: Color(0xFFFFD8C8),
          onPrimaryContainer: Color(0xFF351406),
          secondary: secondaryAccent,
          onSecondary: Color(0xFF111638),
          secondaryContainer: Color(0xFFDCE1FF),
          onSecondaryContainer: Color(0xFF1D2452),
          tertiary: successAccent,
          onTertiary: Color(0xFF102313),
          tertiaryContainer: Color(0xFFD6F3D3),
          onTertiaryContainer: Color(0xFF18341B),
          error: lightError,
          onError: Colors.white,
          errorContainer: Color(0xFFFFDAD7),
          onErrorContainer: Color(0xFF410002),
          surface: lightSurface,
          onSurface: lightOnSurface,
          onSurfaceVariant: lightOnSurfaceVariant,
          outline: lightOutline,
          outlineVariant: Color(0xFFE0E4EC),
          shadow: Colors.black,
          scrim: Colors.black54,
          inverseSurface: Color(0xFF22262F),
          onInverseSurface: darkOnSurface,
          inversePrimary: Color(0xFFFFB694),
          surfaceTint: primaryAccent,
        ).copyWith(
          surfaceContainer: lightSurfaceContainer,
          surfaceContainerHigh: lightSurfaceContainerHigh,
          surfaceContainerHighest: const Color(0xFFDDE2EA),
          surfaceContainerLow: const Color(0xFFF7F8FB),
          surfaceContainerLowest: Colors.white,
        );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
    );
  }

  static ThemeData dark() {
    final colorScheme =
        const ColorScheme(
          brightness: Brightness.dark,
          primary: primaryAccent,
          onPrimary: Color(0xFF2D1308),
          primaryContainer: Color(0xFF4A1E0B),
          onPrimaryContainer: Color(0xFFFFD7C7),
          secondary: secondaryAccent,
          onSecondary: Color(0xFF151B3E),
          secondaryContainer: Color(0xFF26305F),
          onSecondaryContainer: Color(0xFFDCE1FF),
          tertiary: successAccent,
          onTertiary: Color(0xFF132717),
          tertiaryContainer: Color(0xFF27472C),
          onTertiaryContainer: Color(0xFFD9F4D8),
          error: darkError,
          onError: Color(0xFF360404),
          errorContainer: Color(0xFF5C1313),
          onErrorContainer: Color(0xFFFFDAD8),
          surface: darkSurface,
          onSurface: darkOnSurface,
          onSurfaceVariant: darkOnSurfaceVariant,
          outline: darkOutline,
          outlineVariant: Color(0xFF20242D),
          shadow: Colors.black,
          scrim: Colors.black87,
          inverseSurface: Color(0xFFE7EBF3),
          onInverseSurface: Color(0xFF1A1D24),
          inversePrimary: Color(0xFFFFB694),
          surfaceTint: primaryAccent,
        ).copyWith(
          surfaceContainer: darkSurfaceContainer,
          surfaceContainerHigh: darkSurfaceContainerHigh,
          surfaceContainerHighest: const Color(0xFF2A2F39),
          surfaceContainerLow: const Color(0xFF151820),
          surfaceContainerLowest: darkBackground,
        );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
  }) {
    final baseTextTheme = Typography.material2021().white.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
    final textTheme = baseTextTheme.copyWith(
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(height: 1.35),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        height: 1.35,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 0.2,
      ),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scaffoldBackgroundColor,
        elevation: 0,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.18),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: textTheme.bodyMedium,
        helperStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: colorScheme.error, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: colorScheme.primary.withValues(alpha: 0.2),
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: colorScheme.onSurfaceVariant,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colorScheme.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLarge),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary.withValues(alpha: 0.18);
            }
            return colorScheme.surfaceContainer;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onSurface;
            }
            return colorScheme.onSurfaceVariant;
          }),
          side: WidgetStateProperty.all(BorderSide(color: colorScheme.outline)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSmall),
            ),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          textStyle: WidgetStateProperty.all(textTheme.labelLarge),
        ),
      ),
    );
  }
}
