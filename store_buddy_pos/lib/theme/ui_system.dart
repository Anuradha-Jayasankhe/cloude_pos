import 'package:flutter/material.dart';

class UiSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class UiRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 32;
  static const double pill = 999;
}

class UiSize {
  static const double buttonHeight = 48;
  static const double buttonHeightLg = 56;
  static const double inputHeight = 48;
  static const double navRailWidth = 240;
  static const double navRailCollapsedWidth = 72;
  static const double pageMaxContentWidth = 1440;
  static const double topBarHeight = 60;
  static const double sidebarLogoHeight = 72;
}

class UiBreakpoints {
  static const double phone = 600;
  static const double tablet = 980;
  static const double desktop = 1100;
}

class ResponsiveLayout {
  static bool isSmallPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < 380;

  static bool isPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < UiBreakpoints.phone;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= UiBreakpoints.phone && w < UiBreakpoints.tablet;
  }

  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < UiBreakpoints.tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= UiBreakpoints.desktop;

  /// Clamps dialog width relative to screen width with horizontal safety margin
  static double adaptiveDialogWidth(
    BuildContext context,
    double preferredWidth, {
    double maxFraction = 0.94,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxAllowed = screenWidth * maxFraction;
    return preferredWidth > maxAllowed ? maxAllowed : preferredWidth;
  }

  /// Clamps dialog height relative to available screen height & inset bottom (keyboard)
  static double adaptiveDialogHeight(
    BuildContext context,
    double preferredHeight, {
    double maxFraction = 0.90,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        (mediaQuery.size.height - mediaQuery.viewInsets.bottom) * maxFraction;
    return preferredHeight > availableHeight ? availableHeight : preferredHeight;
  }

  /// Calculates dynamic grid column count based on available container width
  static int responsiveGridColumns(
    double width, {
    double minItemWidth = 160,
    int maxColumns = 6,
    int defaultColumns = 1,
  }) {
    if (width <= 0) return defaultColumns;
    final calculated = (width / minItemWidth).floor();
    return calculated.clamp(1, maxColumns);
  }
}

class UiShadows {
  static const List<BoxShadow> light = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 22, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> dark = [
    BoxShadow(color: Color(0x2A000000), blurRadius: 28, offset: Offset(0, 14)),
  ];
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 32, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> glow = [
    BoxShadow(
        color: Color(0x4D6366F1), blurRadius: 24, offset: Offset(0, 0)),
  ];
  static const List<BoxShadow> amberGlow = [
    BoxShadow(
        color: Color(0x4DF59E0B), blurRadius: 20, offset: Offset(0, 0)),
  ];
}

class UiGradients {
  /// Primary brand gradient — indigo → violet
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  /// Extended brand — indigo → violet → pink
  static const LinearGradient brandWide = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFDB2777)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Dark sidebar / hero panel
  static const LinearGradient heroPanel = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF070B14), Color(0xFF0D1525), Color(0xFF1E1B4B)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Sidebar gradient
  static const LinearGradient sidebar = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1525), Color(0xFF111D35)],
  );

  /// Amber / warm accent
  static const LinearGradient amber = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
  );

  /// Success green
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  /// Danger red
  static const LinearGradient danger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );

  /// Light mode page background
  static const LinearGradient lightBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8F9FE), Color(0xFFEEF0FF)],
  );

  /// Dark mode page background
  static const LinearGradient darkBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF070B14), Color(0xFF0D1525)],
  );

  /// Metric card accent top gradient (indigo band)
  static const LinearGradient metricAccent = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  /// Teal/cyan accent (for secondary metrics)
  static const LinearGradient teal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
  );
}

class UiGlass {
  /// Light glass surface opacity
  static const double lightOpacity = 0.08;

  /// Medium glass surface opacity
  static const double mediumOpacity = 0.12;

  /// Strong glass border opacity
  static const double borderOpacity = 0.15;

  /// Blur sigma for glass panels
  static const double blurSigma = 20.0;

  /// Blur sigma for modals
  static const double modalBlurSigma = 30.0;

  /// Glass overlay for dark mode cards
  static Color darkSurface(double opacity) =>
      Colors.white.withValues(alpha: opacity);

  /// Glass overlay for light mode cards
  static Color lightSurface(double opacity) =>
      Colors.white.withValues(alpha: opacity);
}

class UiAnimations {
  /// Fast snap — 120ms, used for hover, focus
  static const Duration fast = Duration(milliseconds: 120);

  /// Standard UI transition — 200ms
  static const Duration standard = Duration(milliseconds: 200);

  /// Page/tab switch — 280ms
  static const Duration page = Duration(milliseconds: 280);

  /// Slow entrance — 400ms, used for page-load stagger
  static const Duration slow = Duration(milliseconds: 400);

  /// Ease-out curve for natural deceleration
  static const Curve easeOut = Curves.easeOutCubic;

  /// Ease-in-out for symmetric transitions
  static const Curve easeInOut = Curves.easeInOutCubic;

  /// Spring-like bounce
  static const Curve spring = Curves.elasticOut;
}

/// Helper to build a gradient text widget
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;

  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient = UiGradients.brand,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}

/// Glassmorphism container widget
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final Color? surfaceColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = UiRadius.lg,
    this.blurSigma = UiGlass.blurSigma,
    this.surfaceColor,
    this.borderColor,
    this.padding,
    this.margin,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: surfaceColor ??
            (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.72)),
        border: Border.all(
          color: borderColor ??
              (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.6)),
        ),
        boxShadow: boxShadow ?? UiShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(UiSpacing.md),
          child: child,
        ),
      ),
    );
  }
}

/// Status chip widget — pill shaped with icon + label
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool outlined;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(UiRadius.pill),
        border: Border.all(
          color: outlined ? color : color.withValues(alpha: 0.3),
          width: outlined ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient icon container
class GradientIconBox extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final double size;
  final double iconSize;
  final double borderRadius;

  const GradientIconBox({
    super.key,
    required this.icon,
    this.gradient = UiGradients.brand,
    this.size = 44,
    this.iconSize = 22,
    this.borderRadius = UiRadius.md,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}
