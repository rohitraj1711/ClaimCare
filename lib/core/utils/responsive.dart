import 'package:flutter/material.dart';

/// Responsive breakpoints and utilities for adaptive layouts.
class Responsive {
  Responsive._();

  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Check if the screen is mobile size
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Check if the screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Check if the screen is desktop size
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  /// Check if sidebar should be visible (tablet and up)
  static bool showSidebar(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  /// Get responsive value based on screen size
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// Get responsive padding
  static EdgeInsets padding(BuildContext context) {
    return value(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }

  /// Get responsive horizontal padding
  static double horizontalPadding(BuildContext context) {
    return value(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
  }

  /// Get number of grid columns
  static int gridColumns(BuildContext context) {
    return value(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 4,
    );
  }

  /// Get card width for summary cards
  static double summaryCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) {
      return screenWidth - 32; // Full width with padding
    }
    if (isTablet(context)) {
      return (screenWidth - 72) / 2; // Two cards with padding
    }
    return 280; // Fixed width on desktop
  }
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (Responsive.isTablet(context)) return tablet ?? mobile;
    return mobile;
  }
}

/// Responsive grid layout
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.gridColumns(context);
    
    if (columns == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children
            .map((child) => Padding(
                  padding: EdgeInsets.only(bottom: runSpacing),
                  child: child,
                ))
            .toList(),
      );
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children,
    );
  }
}
