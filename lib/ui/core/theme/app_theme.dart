import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const calorieAccent = Color(0xFFFF7A59);
  static const proteinAccent = Color(0xFF6EA8FF);
  static const carbAccent = Color(0xFFFFC857);
  static const fatAccent = Color(0xFF43C6AC);

  static const darkBackground = Color(0xFF121414);
  static const darkSurface = Color(0xFF121414);
  static const darkSurfaceContainer = Color(0xFF1E2020);
  static const darkSurfaceContainerHigh = Color(0xFF282A2B);
  static const darkOutline = Color(0xFF8E9379);
  static const darkOnSurface = Color(0xFFE2E2E2);
  static const darkOnSurfaceVariant = Color(0xFFC4C9AC);
  static const darkError = Color(0xFFFFB4AB);

  static const lightBackground = Color(0xFFF9F9F9);
  static const lightSurface = Color(0xFFF9F9F9);
  static const lightSurfaceContainer = Color(0xFFEEEEEE);
  static const lightSurfaceContainerHigh = Color(0xFFE8E8E8);
  static const lightOutline = Color(0xFF747A60);
  static const lightOnSurface = Color(0xFF1A1C1C);
  static const lightOnSurfaceVariant = Color(0xFF444933);
  static const lightError = Color(0xFFBA1A1A);

  static const radiusSmall = 8.0;
  static const radiusMedium = 12.0;
  static const radiusLarge = 16.0;

  static const spacingXSmall = 4.0;
  static const spacingSmall = 8.0;
  static const spacingMedium = 16.0;
  static const spacingLarge = 24.0;

  static const _lightBorder = Color(0xFFE5E7EB);
  static const _lightSubtleBackground = Color(0xFFF4F4F4);

  static ThemeData light() {
    final colorScheme =
        const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF506600),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFCCFF00),
          onPrimaryContainer: Color(0xFF5B7300),
          secondary: Color(0xFF5F5E5E),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFE2DFDE),
          onSecondaryContainer: Color(0xFF636262),
          tertiary: Color(0xFF4F616E),
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xFFDCEFFF),
          onTertiaryContainer: Color(0xFF5B6D7A),
          error: lightError,
          onError: Colors.white,
          errorContainer: Color(0xFFFFDAD6),
          onErrorContainer: Color(0xFF93000A),
          surface: lightSurface,
          onSurface: lightOnSurface,
          onSurfaceVariant: lightOnSurfaceVariant,
          outline: lightOutline,
          outlineVariant: Color(0xFFC4C9AC),
          shadow: Colors.black,
          scrim: Colors.black54,
          inverseSurface: Color(0xFF2F3131),
          onInverseSurface: Color(0xFFF1F1F1),
          inversePrimary: Color(0xFFABD600),
          surfaceTint: Color(0xFF506600),
        ).copyWith(
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFF3F3F3),
          surfaceContainer: lightSurfaceContainer,
          surfaceContainerHigh: lightSurfaceContainerHigh,
          surfaceContainerHighest: const Color(0xFFE2E2E2),
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
          primary: Colors.white,
          onPrimary: Color(0xFF283500),
          primaryContainer: Color(0xFFC3F400),
          onPrimaryContainer: Color(0xFF556D00),
          secondary: Color(0xFFC8C6C5),
          onSecondary: Color(0xFF313030),
          secondaryContainer: Color(0xFF474746),
          onSecondaryContainer: Color(0xFFB7B5B4),
          tertiary: Colors.white,
          onTertiary: Color(0xFF21323E),
          tertiaryContainer: Color(0xFFD2E5F5),
          onTertiaryContainer: Color(0xFF556774),
          error: darkError,
          onError: Color(0xFF690005),
          errorContainer: Color(0xFF93000A),
          onErrorContainer: Color(0xFFFFDAD6),
          surface: darkSurface,
          onSurface: darkOnSurface,
          onSurfaceVariant: darkOnSurfaceVariant,
          outline: darkOutline,
          outlineVariant: Color(0xFF444933),
          shadow: Colors.black,
          scrim: Colors.black87,
          inverseSurface: Color(0xFFE2E2E2),
          onInverseSurface: Color(0xFF2F3131),
          inversePrimary: Color(0xFF506600),
          surfaceTint: Color(0xFFABD600),
        ).copyWith(
          surfaceContainerLowest: const Color(0xFF0C0F0F),
          surfaceContainerLow: const Color(0xFF1A1C1C),
          surfaceContainer: darkSurfaceContainer,
          surfaceContainerHigh: darkSurfaceContainerHigh,
          surfaceContainerHighest: const Color(0xFF333535),
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
    final baseTextTheme = _baseTextTheme(colorScheme.brightness).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
    final textTheme = _textTheme(baseTextTheme, colorScheme);
    final base = ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      canvasColor: scaffoldBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            standardSurfaceRadius(colorScheme.brightness),
          ),
          side: BorderSide(color: surfaceBorderColor(colorScheme)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? colorScheme.onPrimaryContainer
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
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scaffoldBackgroundColor,
        elevation: 0,
        indicatorColor: colorScheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor(colorScheme),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingMedium,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            standardSurfaceRadius(colorScheme.brightness),
          ),
          borderSide: BorderSide(color: surfaceBorderColor(colorScheme)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            standardSurfaceRadius(colorScheme.brightness),
          ),
          borderSide: BorderSide(color: surfaceBorderColor(colorScheme)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            standardSurfaceRadius(colorScheme.brightness),
          ),
          borderSide: BorderSide(color: colorScheme.primaryContainer, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            standardSurfaceRadius(colorScheme.brightness),
          ),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            standardSurfaceRadius(colorScheme.brightness),
          ),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(
            color: colorScheme.brightness == Brightness.light
                ? colorScheme.onSurface
                : surfaceBorderColor(colorScheme),
          ),
          backgroundColor: colorScheme.brightness == Brightness.light
              ? colorScheme.surfaceContainerLowest
              : Colors.transparent,
          foregroundColor: colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          foregroundColor: colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide(color: surfaceBorderColor(colorScheme)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingXSmall,
        ),
        iconColor: colorScheme.onSurfaceVariant,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colorScheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(color: surfaceBorderColor(colorScheme)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primaryContainer;
            }
            return colorScheme.surfaceContainerLow;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onPrimaryContainer;
            }
            return colorScheme.onSurfaceVariant;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: surfaceBorderColor(colorScheme)),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
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

  static TextTheme _baseTextTheme(Brightness brightness) {
    return brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme colorScheme) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: 'Lexend',
        fontSize: 40,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontFamily: 'Lexend',
        fontSize: 32,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontFamily: 'Lexend',
        fontSize: 24,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: 'Lexend',
        fontSize: 24,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.24,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: 'Lexend',
        fontSize: 18,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: 'Lexend',
        fontSize: 18,
        height: 1.6,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: 'Lexend',
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurfaceVariant,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontFamily: 'Lexend',
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontFamily: 'Lexend',
        fontSize: 12,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontFamily: 'Lexend',
        fontSize: 12,
        height: 1,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 0.6,
      ),
    );
  }

  static Color surfaceBorderColor(ColorScheme colorScheme) {
    if (colorScheme.brightness == Brightness.light) {
      return _lightBorder;
    }
    return colorScheme.outlineVariant;
  }

  static Color inputFillColor(ColorScheme colorScheme) {
    if (colorScheme.brightness == Brightness.light) {
      return colorScheme.surfaceContainerLowest;
    }
    return colorScheme.surfaceContainer;
  }

  static Color progressTrackColor(ColorScheme colorScheme) {
    if (colorScheme.brightness == Brightness.light) {
      return _lightSubtleBackground;
    }
    return colorScheme.surfaceContainerHigh;
  }

  static List<BoxShadow> ambientShadow(Brightness brightness) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static double standardSurfaceRadius(Brightness brightness) {
    return 8;
  }
}
