import 'package:flutter/material.dart';

/// Responsive breakpoints untuk berbagai ukuran layar
class ResponsiveBreakpoints {
  // Breakpoints
  static const double mobile = 480;
  static const double mobileLarge = 600;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double desktopLarge = 1440;

  // Sidebar widths
  static const double sidebarMobile = 0; // Hidden on mobile
  static const double sidebarTablet = 220;
  static const double sidebarDesktop = 280;
}

/// Helper class untuk responsive design dengan MediaQuery
class ResponsiveHelper {
  final BuildContext context;

  ResponsiveHelper(this.context);

  /// Screen width
  double get width => MediaQuery.of(context).size.width;

  /// Screen height
  double get height => MediaQuery.of(context).size.height;

  /// Device padding (status bar, notch, etc)
  EdgeInsets get padding => MediaQuery.of(context).padding;

  /// Device view insets (keyboard, etc)
  EdgeInsets get viewInsets => MediaQuery.of(context).viewInsets;

  /// Check if mobile (< 600px)
  bool get isMobile => width < ResponsiveBreakpoints.mobileLarge;

  /// Check if tablet (600px - 1024px)
  bool get isTablet => width >= ResponsiveBreakpoints.mobileLarge && width < ResponsiveBreakpoints.desktop;

  /// Check if desktop (>= 1024px)
  bool get isDesktop => width >= ResponsiveBreakpoints.desktop;

  /// Check if small mobile (< 480px)
  bool get isSmallMobile => width < ResponsiveBreakpoints.mobile;

  /// Check if large desktop (>= 1440px)
  bool get isLargeDesktop => width >= ResponsiveBreakpoints.desktopLarge;

  /// Orientation (portrait or landscape)
  Orientation get orientation => MediaQuery.of(context).orientation;

  /// Is portrait mode
  bool get isPortrait => orientation == Orientation.portrait;

  /// Is landscape mode
  bool get isLandscape => orientation == Orientation.landscape;

  /// Device pixel ratio
  double get devicePixelRatio => MediaQuery.of(context).devicePixelRatio;

  /// Safely check if keyboard is visible
  bool get isKeyboardVisible => viewInsets.bottom > 0;

  /// Get sidebar width based on screen size
  double get sidebarWidth {
    if (isMobile) return ResponsiveBreakpoints.sidebarMobile;
    if (isTablet) return ResponsiveBreakpoints.sidebarTablet;
    return ResponsiveBreakpoints.sidebarDesktop;
  }

  /// Get content padding based on screen size
  EdgeInsets get contentPadding {
    if (isMobile) return const EdgeInsets.all(12);
    if (isTablet) return const EdgeInsets.all(16);
    return const EdgeInsets.all(24);
  }

  /// Get responsive spacing
  double getSpacing({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  /// Get responsive font size
  double getFont({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return getSpacing(mobile: mobile, tablet: tablet, desktop: desktop);
  }

  /// Get responsive size for fixed aspect ratio elements
  Size getResponsiveSize({
    required double mobileWidth,
    required double mobileHeight,
    double? tabletWidth,
    double? tabletHeight,
    double? desktopWidth,
    double? desktopHeight,
  }) {
    if (isDesktop && desktopWidth != null && desktopHeight != null) {
      return Size(desktopWidth, desktopHeight);
    }
    if (isTablet && tabletWidth != null && tabletHeight != null) {
      return Size(tabletWidth, tabletHeight);
    }
    return Size(mobileWidth, mobileHeight);
  }

  /// Get cross axis count for grid layouts
  int getGridCount({
    int mobile = 1,
    int? tablet,
    int? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  /// Get max width for content (useful for desktop centering)
  double get maxContentWidth {
    if (isDesktop) return 1200;
    if (isTablet) return 800;
    return width;
  }
}

/// Extension untuk mudah mengakses ResponsiveHelper
extension ResponsiveContext on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);

  bool get isMobile => responsive.isMobile;
  bool get isTablet => responsive.isTablet;
  bool get isDesktop => responsive.isDesktop;
  bool get isPortrait => responsive.isPortrait;
  bool get isLandscape => responsive.isLandscape;
  double get width => responsive.width;
  double get height => responsive.height;
}
