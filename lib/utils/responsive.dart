import 'package:flutter/material.dart';

/// Layout breakpoints tuned for mobile web, tablet, and desktop.
abstract final class Breakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;
  static const double wide = 1400;
  static const double railExtended = 900;
  static const double contentMax = 960;
  static const double contentWide = 1280;
  static const double sidebarWidth = 260;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isMobile => screenWidth < Breakpoints.tablet;

  bool get isTablet =>
      screenWidth >= Breakpoints.tablet && screenWidth < Breakpoints.desktop;

  bool get isDesktop => screenWidth >= Breakpoints.desktop;

  bool get isWide => screenWidth >= Breakpoints.wide;

  bool get useNavigationRail =>
      screenWidth >= Breakpoints.tablet && screenWidth < Breakpoints.desktop;

  bool get useDesktopShell => screenWidth >= Breakpoints.desktop;

  double get contentMaxWidth {
    if (isWide) return 1440;
    if (isDesktop) return Breakpoints.contentWide;
    if (isTablet) return Breakpoints.contentMax;
    return double.infinity;
  }

  EdgeInsets get pagePadding {
    if (isMobile) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    }
    if (isTablet) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 40, vertical: 24);
  }

  int get dashboardColumns {
    if (isWide) return 4;
    if (isDesktop) return 4;
    if (isTablet) return 2;
    return 1;
  }

  int get listColumns {
    if (isWide) return 3;
    if (isDesktop) return 2;
    if (screenWidth >= 840) return 2;
    return 1;
  }
}

/// Centers page content and caps width on larger screens.
class AdaptiveBody extends StatelessWidget {
  const AdaptiveBody({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final horizontalPad = padding ?? context.pagePadding;
    final width = maxWidth ?? context.contentMaxWidth;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Padding(
          padding: horizontalPad,
          child: child,
        ),
      ),
    );
  }
}

/// Responsive row of stat boxes — stacks on very narrow widths.
class ResponsiveStatRow extends StatelessWidget {
  const ResponsiveStatRow({
    super.key,
    required this.children,
    this.compactBelow = 520,
  });

  final List<Widget> children;
  final double compactBelow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = constraints.maxWidth < compactBelow;

        if (stackVertically) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                children[i],
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}
