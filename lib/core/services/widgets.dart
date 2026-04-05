import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Stat Card ─────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.7), size: 14),
              ],
            ),
            const Spacer(),
            Text(value, style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white,
            )),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              fontSize: 12, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w500,
            )),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: TextStyle(
                fontSize: 10, color: Colors.white.withValues(alpha: 0.65),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!, style: const TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13,
            )),
          ),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key, required this.icon, required this.message,
    this.actionLabel, this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMid, fontSize: 14)),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── App Card ──────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

// ── Avatar Badge ──────────────────────────────────────────
class AvatarBadge extends StatelessWidget {
  final String name;
  final String? subtitle;
  final Color color;

  const AvatarBadge({super.key, required this.name, this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ')
        .take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join();
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(initials, style: TextStyle(
            color: color, fontWeight: FontWeight.w700, fontSize: 14,
          )),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark,
              )),
              if (subtitle != null) Text(subtitle!, style: const TextStyle(
                fontSize: 12, color: AppColors.textLight,
              )),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Status Badge ──────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(
        color: color, fontSize: 11, fontWeight: FontWeight.w700,
      )),
    );
  }
}

// ── Loading Overlay ───────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final String? message;
  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(color: AppColors.primary),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!, style: const TextStyle(color: AppColors.textMid)),
            ],
          ]),
        ),
      ),
    );
  }
}

// ── Snackbar helpers ──────────────────────────────────────
void showSuccess(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.check_circle, color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg)),
    ]),
    backgroundColor: AppColors.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));
}

void showError(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.error_outline, color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg)),
    ]),
    backgroundColor: AppColors.error,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));
}

// ── Confirm Dialog ────────────────────────────────────────
Future<bool> showConfirmDialog(BuildContext context, {
  required String title, required String message,
  String confirmLabel = 'Hapus', Color confirmColor = AppColors.error,
}) async {
  return await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMid))),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          child: Text(confirmLabel),
        ),
      ],
    ),
  ) ?? false;
}
