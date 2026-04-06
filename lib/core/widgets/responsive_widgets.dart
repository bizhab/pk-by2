import 'package:flutter/material.dart';
import '../utils/responsive.dart';

/// Responsive grid view yang otomatis menyesuaikan jumlah columns
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileCount;
  final int tabletCount;
  final int desktopCount;
  final double spacing;
  final double runSpacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  const ResponsiveGrid({
    required this.children,
    this.mobileCount = 1,
    this.tabletCount = 2,
    this.desktopCount = 3,
    this.spacing = 16,
    this.runSpacing = 16,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = context.responsive.getGridCount(
      mobile: mobileCount,
      tablet: tabletCount,
      desktop: desktopCount,
    );

    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: 1,
      mainAxisSpacing: runSpacing,
      crossAxisSpacing: spacing,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      children: children,
    );
  }
}

/// Responsive wrap untuk layout yang fleksibel
class ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;
  final WrapAlignment runAlignment;
  final WrapCrossAlignment crossAxisAlignment;

  const ResponsiveWrap({
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.alignment = WrapAlignment.start,
    this.runAlignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      runAlignment: runAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}

/// Responsive layout yang berubah dari column (mobile) ke row (desktop)
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return context.isMobile
        ? mobile
        : context.isTablet
            ? (tablet ?? mobile)
            : (desktop ?? tablet ?? mobile);
  }
}

/// Builder yang memberikan info responsive untuk children
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveHelper responsive) builder;

  const ResponsiveBuilder({required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(context, context.responsive);
  }
}

/// Stack adaptive untuk position elements responsively
class ResponsiveStack extends StatelessWidget {
  final List<Widget> children;
  final Alignment alignment;
  final TextDirection? textDirection;
  final StackFit fit;
  final Clip clipBehavior;

  const ResponsiveStack({
    required this.children,
    this.alignment = Alignment.topLeft,
    this.textDirection,
    this.fit = StackFit.loose,
    this.clipBehavior = Clip.hardEdge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: alignment,
      textDirection: textDirection,
      fit: fit,
      clipBehavior: clipBehavior,
      children: children,
    );
  }
}

/// Responsive Sliver Grid untuk scroll views
class ResponsiveSliverGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileCount;
  final int tabletCount;
  final int desktopCount;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const ResponsiveSliverGrid({
    required this.children,
    this.mobileCount = 1,
    this.tabletCount = 2,
    this.desktopCount = 3,
    this.childAspectRatio = 1,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = context.responsive.getGridCount(
      mobile: mobileCount,
      tablet: tabletCount,
      desktop: desktopCount,
    );

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => children[index],
        childCount: children.length,
      ),
    );
  }
}

/// Space widget yang responsive
class ResponsiveSpace extends StatelessWidget {
  final double mobile;
  final double? tablet;
  final double? desktop;
  final bool horizontal;

  const ResponsiveSpace.vertical({
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : horizontal = false;

  const ResponsiveSpace.horizontal({
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : horizontal = true;

  @override
  Widget build(BuildContext context) {
    final size = context.responsive.getSpacing(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );

    return horizontal
        ? SizedBox(width: size)
        : SizedBox(height: size);
  }
}

/// Responsive padding menggunakan EdgeInsets
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets mobile;
  final EdgeInsets? tablet;
  final EdgeInsets? desktop;

  const ResponsivePadding({
    required this.child,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    late EdgeInsets padding;
    if (context.isDesktop && desktop != null) {
      padding = desktop!;
    } else if (context.isTablet && tablet != null) {
      padding = tablet!;
    } else {
      padding = mobile;
    }

    return Padding(padding: padding, child: child);
  }
}

/// Responsive text yang scale berdasarkan screen size
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double mobileSize;
  final double? tabletSize;
  final double? desktopSize;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const ResponsiveText(
    this.text, {
    this.style,
    required this.mobileSize,
    this.tabletSize,
    this.desktopSize,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = context.responsive.getFont(
      mobile: mobileSize,
      tablet: tabletSize,
      desktop: desktopSize,
    );

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(fontSize: fontSize),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
