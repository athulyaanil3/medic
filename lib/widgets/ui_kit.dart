import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Frosted white card with soft shadow.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.cardWhite.withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1.2,
        ),
        boxShadow: [AppTheme.softShadow(0.08)],
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: card,
      ),
    );
  }
}

/// Page title row with optional trailing action.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                    height: 1.15,
                  ),
                ),

                if (subtitle != null) ...[
                  const SizedBox(height: 6),

                  Text(
                    subtitle!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      color: AppTheme.inkMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Circular icon container used in lists and explore tiles.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.gradient = AppTheme.heroGradient,
    this.size = 52,
  });

  final IconData icon;
  final Gradient gradient;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,

      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: AppTheme.deepTeal.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Icon(
        icon,
        color: Colors.white,
        size: size * 0.48,
      ),
    );
  }
}

/// Gradient stat card for dashboard metrics.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.gradient = AppTheme.heroGradient,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),

        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [AppTheme.softShadow(0.22)],
          ),

          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Container(
                  padding: const EdgeInsets.all(10),

                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius:
                    BorderRadius.circular(14),
                  ),

                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Explore / feature list row.
class FeatureRow extends StatelessWidget {
  const FeatureRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.accent = AppTheme.heroGradient,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Gradient accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        child: Row(
          children: [
            IconBadge(
              icon: icon,
              gradient: accent,
              size: 50,
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.inkMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color:
              AppTheme.inkMuted.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill chip for times / tags.
class MediChip extends StatelessWidget {
  const MediChip({
    super.key,
    required this.label,
    this.icon,
  });

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),

      decoration: BoxDecoration(
        color: AppTheme.mintGlow.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),

        border: Border.all(
          color:
          AppTheme.tealLight.withOpacity(0.25),
        ),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: AppTheme.deepTeal,
            ),

            const SizedBox(width: 6),
          ],

          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.deepTeal,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient FAB-style extended button.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient:
        onPressed == null
            ? null
            : AppTheme.heroGradient,

        borderRadius: BorderRadius.circular(18),

        boxShadow:
        onPressed == null
            ? null
            : [AppTheme.softShadow(0.2)],
      ),

      child: Material(
        color:
        onPressed == null
            ? AppTheme.inkMuted.withOpacity(0.3)
            : Colors.transparent,

        borderRadius: BorderRadius.circular(18),

        child: InkWell(
          onTap: busy ? null : onPressed,

          borderRadius: BorderRadius.circular(18),

          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16,
            ),

            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.center,

              children: [
                if (busy)
                  const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white),

                    const SizedBox(width: 10),
                  ],

                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}