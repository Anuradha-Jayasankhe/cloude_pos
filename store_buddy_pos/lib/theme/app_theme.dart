import 'package:flutter/material.dart';

import 'ui_system.dart';

class AppTheme {
  // ──────────────────────── Brand Colour Tokens ───────────────────────────
  static const Color brandIndigo = Color(0xFF6366F1);
  static const Color brandViolet = Color(0xFF8B5CF6);
  static const Color brandAmber = Color(0xFFF59E0B);
  static const Color brandPink = Color(0xFFEC4899);
  static const Color brandTeal = Color(0xFF0EA5E9);
  static const Color brandEmerald = Color(0xFF10B981);
  static const Color brandRose = Color(0xFFEF4444);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  // ──────────────────────── Light Mode ────────────────────────────────────
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: Color(0xFF4F46E5), // Indigo 600
      onPrimary: Colors.white,
      secondary: Color(0xFF7C3AED), // Violet 600
      onSecondary: Colors.white,
      tertiary: Color(0xFFF59E0B), // Amber
      onTertiary: Colors.white,
      error: Color(0xFFDC2626),
      onError: Colors.white,
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF0F172A),
      surfaceContainerHighest: Color(0xFFF1F3FF),
      outline: Color(0xFFE0E7FF),
      outlineVariant: Color(0xFFEEEFF8),
    );

    return _baseTheme(scheme, Brightness.light).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF5F6FF),
      canvasColor: const Color(0xFFF5F6FF),
      cardTheme: _cardTheme(
        border: const Color(0xFFE0E4FF),
        color: Colors.white,
        shadowColor: const Color(0x0F4F46E5),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        borderColor: const Color(0xFFDDE1F5),
        fillColor: const Color(0xFFFAFAFF),
        focusedColor: scheme.primary,
      ),
      switchTheme: _switchTheme(
        active: scheme.primary,
        inactiveTrack: const Color(0xFFDDE1F5),
      ),
      checkboxTheme: _checkboxTheme(scheme.primary),
      dividerTheme: const DividerThemeData(color: Color(0xFFE8EAFF)),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        shadowColor: Color(0x0A4F46E5),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface.withValues(alpha: 0.65)),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary.withValues(alpha: 0.75),
        textColor: scheme.onSurface,
        selectedColor: scheme.primary,
        selectedTileColor: scheme.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiRadius.md),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        elevation: 12,
        shadowColor: const Color(0x1A4F46E5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiRadius.lg),
          side: const BorderSide(color: Color(0xFFE0E4FF)),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(UiRadius.sm),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ──────────────────────── Dark Mode ─────────────────────────────────────
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: Color(0xFF818CF8), // Indigo 400 (lightened for dark bg)
      onPrimary: Color(0xFF1E1B4B),
      secondary: Color(0xFFA78BFA), // Violet 400
      onSecondary: Color(0xFF2E1065),
      tertiary: Color(0xFFFBBF24), // Amber 400
      onTertiary: Color(0xFF451A03),
      error: Color(0xFFF87171),
      onError: Color(0xFF450A0A),
      surface: Color(0xFF111827), // Gray 900
      onSurface: Color(0xFFF1F5F9),
      surfaceContainerHighest: Color(0xFF1E293B),
      outline: Color(0xFF1E2D45),
      outlineVariant: Color(0xFF162035),
    );

    return _baseTheme(scheme, Brightness.dark).copyWith(
      scaffoldBackgroundColor: const Color(0xFF070B14),
      canvasColor: const Color(0xFF070B14),
      cardTheme: _cardTheme(
        border: const Color(0xFF1E2D45),
        color: const Color(0xFF111827),
        shadowColor: Colors.black26,
      ),
      inputDecorationTheme: _inputDecorationTheme(
        borderColor: const Color(0xFF1E2D45),
        fillColor: const Color(0xFF111827),
        focusedColor: scheme.primary,
      ),
      switchTheme: _switchTheme(
        active: scheme.primary,
        inactiveTrack: const Color(0xFF1E2D45),
      ),
      checkboxTheme: _checkboxTheme(scheme.primary),
      dividerTheme: const DividerThemeData(color: Color(0xFF1E2D45)),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D1525),
        foregroundColor: Color(0xFFF1F5F9),
        elevation: 0,
        shadowColor: Colors.black45,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF0D1525),
        surfaceTintColor: Colors.transparent,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface.withValues(alpha: 0.75)),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary.withValues(alpha: 0.85),
        textColor: scheme.onSurface,
        selectedColor: scheme.primary,
        selectedTileColor: scheme.primary.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiRadius.md),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF111827),
        elevation: 16,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiRadius.lg),
          side: const BorderSide(color: Color(0xFF1E2D45)),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(UiRadius.sm),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        textStyle: const TextStyle(
          color: Color(0xFFF1F5F9),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ──────────────────────── Base Theme ────────────────────────────────────
  static ThemeData _baseTheme(ColorScheme scheme, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: 'Geist',
    );

    final text = base.textTheme;
    return base.copyWith(
      textTheme: text.copyWith(
        displayLarge: text.displayLarge?.copyWith(
          fontSize: 52,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          height: 1.1,
        ),
        displayMedium: text.displayMedium?.copyWith(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
          height: 1.15,
        ),
        headlineLarge: text.headlineLarge?.copyWith(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          height: 1.25,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          height: 1.3,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        titleSmall: text.titleSmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        bodyLarge: text.bodyLarge?.copyWith(fontSize: 15, height: 1.5),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 13.5, height: 1.5),
        bodySmall: text.bodySmall?.copyWith(fontSize: 12, height: 1.4),
        labelLarge: text.labelLarge?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelMedium: text.labelMedium?.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        labelSmall: text.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(
            const Size(0, UiSize.buttonHeight),
          ),
          elevation: WidgetStateProperty.all(0),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.black.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.08);
            }
            return null;
          }),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: UiSpacing.lg),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UiRadius.md),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(
            const Size(0, UiSize.buttonHeight),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return BorderSide(color: scheme.primary, width: 1.5);
            }
            return BorderSide(
              color: scheme.outline,
              width: 1.0,
            );
          }),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: UiSpacing.lg),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UiRadius.md),
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(
            const Size(0, UiSize.buttonHeight),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: UiSpacing.sm),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UiRadius.md),
            ),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.50),
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiRadius.md),
        ),
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        elevation: 24,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiRadius.xl),
        ),
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF111827)
            : Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: brightness == Brightness.dark
              ? const Color(0xFFF1F5F9)
              : const Color(0xFF0F172A),
          letterSpacing: -0.2,
          fontFamily: 'Geist',
        ),
        contentTextStyle: TextStyle(
          fontSize: 13.5,
          color: brightness == Brightness.dark
              ? const Color(0xFFF1F5F9).withValues(alpha: 0.75)
              : const Color(0xFF334155),
          fontFamily: 'Geist',
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowHeight: 46,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 60,
        horizontalMargin: 16,
        columnSpacing: 16,
        headingTextStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: scheme.onSurface.withValues(alpha: 0.55),
        ),
        dataTextStyle: TextStyle(
          fontSize: 13.5,
          color: scheme.onSurface,
        ),
        dividerThickness: 0.5,
      ),
      chipTheme: ChipThemeData(
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BorderSide.none;
          }
          return BorderSide(
            color: scheme.outline,
            width: 1.0,
          );
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiRadius.pill),
        ),
        backgroundColor: scheme.surface,
        selectedColor: brandIndigo,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        circularTrackColor: scheme.primary.withValues(alpha: 0.12),
      ),
    );
  }

  // ──────────────────────── Component Helpers ──────────────────────────────
  static CardThemeData _cardTheme({
    required Color border,
    required Color color,
    required Color shadowColor,
  }) {
    return CardThemeData(
      color: color,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiRadius.lg),
        side: BorderSide(color: border, width: 1),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required Color borderColor,
    required Color fillColor,
    required Color focusedColor,
  }) {
    const radius = UiRadius.md;
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      constraints: const BoxConstraints(minHeight: UiSize.inputHeight),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: UiSpacing.md,
        vertical: UiSpacing.sm,
      ),
      hintStyle: TextStyle(
        fontSize: 13.5,
        color: const Color(0xFF94A3B8),
        fontWeight: FontWeight.w400,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: focusedColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }

  static CheckboxThemeData _checkboxTheme(Color activeColor) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return activeColor;
        }
        return Colors.transparent;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      side: BorderSide(color: activeColor.withValues(alpha: 0.4), width: 1.5),
    );
  }

  static SwitchThemeData _switchTheme({
    required Color active,
    required Color inactiveTrack,
  }) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return active;
        }
        return inactiveTrack;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );
  }

  // ──────────────────────── Convenience Helpers ────────────────────────────

  /// Returns a gradient button decoration for use with InkWell + Container combos
  static BoxDecoration gradientButtonDecoration({
    bool disabled = false,
    double borderRadius = UiRadius.md,
  }) {
    return BoxDecoration(
      gradient: disabled ? null : UiGradients.brand,
      color: disabled ? const Color(0xFF334155) : null,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: disabled ? null : UiShadows.glow,
    );
  }

  /// Status color resolver
  static Color statusColor(String status) {
    final s = status.trim().toUpperCase();
    if (s == 'ACTIVE' || s == 'COMPLETED' || s == 'PAID' || s == 'APPROVED') {
      return AppTheme.brandEmerald;
    }
    if (s == 'PENDING' || s == 'IN_PROGRESS' || s == 'PROCESSING') {
      return AppTheme.brandAmber;
    }
    if (s == 'CANCELLED' || s == 'FAILED' || s == 'REJECTED' || s == 'OVERDUE') {
      return AppTheme.brandRose;
    }
    if (s == 'INACTIVE' || s == 'DISABLED') {
      return const Color(0xFF64748B);
    }
    return AppTheme.brandIndigo;
  }
}
