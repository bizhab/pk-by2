import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';

/// Adaptive dashboard layout yang responsif
/// Menampilkan sidebar di desktop/tablet, drawer di mobile
class AdaptiveDashboardLayout extends StatefulWidget {
  final String title;
  final Widget Function(BuildContext context) sidebarBuilder;
  final Widget body;
  final FloatingActionButton? fab;
  final Color? backgroundColor;

  const AdaptiveDashboardLayout({
    required this.title,
    required this.sidebarBuilder,
    required this.body,
    this.fab,
    this.backgroundColor,
  });

  @override
  State<AdaptiveDashboardLayout> createState() => _AdaptiveDashboardLayoutState();
}

class _AdaptiveDashboardLayoutState extends State<AdaptiveDashboardLayout> {
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    // Mobile: Drawer + AppBar
    if (responsive.isMobile) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        drawer: Drawer(child: widget.sidebarBuilder(context)),
        body: widget.body,
        floatingActionButton: widget.fab,
        backgroundColor: widget.backgroundColor ?? AppColors.background,
      );
    }
    
    // Tablet & Desktop: Sidebar + Body
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? AppColors.background,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: responsive.sidebarWidth,
            color: AppColors.primary,
            child: widget.sidebarBuilder(context),
          ),
          // Body
          Expanded(
            child: widget.body,
          ),
        ],
      ),
      floatingActionButton: widget.fab,
    );
  }
}

/// Adaptive navigation dengan logo dan back button
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onMenuPressed;
  final Color backgroundColor;
  final Color foregroundColor;

  const AdaptiveAppBar({
    required this.title,
    this.actions,
    this.leading,
    this.onMenuPressed,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      actions: actions,
      leading: leading ?? (context.isMobile ? null : const SizedBox()),
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Responsive content container dengan max width constraints
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool centered;

  const ResponsiveContainer({
    required this.child,
    this.padding,
    this.centered = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final padding = this.padding ?? responsive.contentPadding;

    Widget content = Padding(padding: padding, child: child);

    if (centered && responsive.isDesktop) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Section dengan responsive padding
class ResponsiveSection extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final VoidCallback? onAction;
  final String? actionText;

  const ResponsiveSection({
    this.title,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md16, right: AppSpacing.md16, bottom: AppSpacing.md16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title!, style: Theme.of(context).textTheme.headlineSmall),
                if (actionText != null && onAction != null)
                  TextButton(
                    onPressed: onAction,
                    child: Text(actionText!),
                  ),
              ],
            ),
          ),
        ],
        Container(
          color: backgroundColor,
          child: Padding(padding: padding ?? const EdgeInsets.all(AppSpacing.md16), child: child),
        ),
      ],
    );
  }
}

/// Responsive grid card layout
class ResponsiveCardGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileCount;
  final int tabletCount;
  final int desktopCount;
  final double spacing;

  const ResponsiveCardGrid({
    required this.children,
    this.mobileCount = 1,
    this.tabletCount = 2,
    this.desktopCount = 3,
    this.spacing = AppSpacing.md16,
  });

  @override
  Widget build(BuildContext context) {
    final colCount = context.responsive.getGridCount(
      mobile: mobileCount,
      tablet: tabletCount,
      desktop: desktopCount,
    );

    return GridView.count(
      crossAxisCount: colCount,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

/// Button yang responsif
class ResponsiveButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool expanded;
  final ButtonStyle? style;

  const ResponsiveButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.expanded = true,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Responsive dialog helper
class ResponsiveDialog extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? icon;

  const ResponsiveDialog({
    required this.title,
    required this.body,
    this.actions,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.responsive.getSpacing(
          mobile: AppSpacing.md16,
          tablet: AppSpacing.lg24,
        ),
        vertical: AppSpacing.md16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(height: AppSpacing.md16),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md16),
              body,
              if (actions != null) ...[
                const SizedBox(height: AppSpacing.lg24),
                Wrap(
                  spacing: AppSpacing.md16,
                  runSpacing: AppSpacing.md16,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive list tile dengan adaptive layout
class ResponsiveListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? tileColor;

  const ResponsiveListTile({
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.tileColor,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return ListTile(
        leading: leading,
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing,
        onTap: onTap,
        tileColor: tileColor,
      );
    }

    return Card(
      color: tileColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md16, vertical: AppSpacing.sm12),
        child: Row(
          children: [
            if (leading != null) ...[
              SizedBox(
                width: 56,
                height: 56,
                child: Center(child: leading!),
              ),
              const SizedBox(width: AppSpacing.md16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs4),
                    Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.md16),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Responsive vertical divider dengan text
class ResponsiveSectionDivider extends StatelessWidget {
  final String? text;
  final Color color;
  final double thickness;

  const ResponsiveSectionDivider({
    this.text,
    this.color = AppColors.divider,
    this.thickness = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (text == null) {
      return Divider(color: color, thickness: thickness);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md16),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: color, thickness: thickness),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md16),
            child: Text(
              text!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Divider(color: color, thickness: thickness),
          ),
        ],
      ),
    );
  }
}
