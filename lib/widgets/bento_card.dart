import 'package:flutter/material.dart';
import '../core/app_theme.dart';

enum ShadowStyle { none, light, heavy, button }

class BentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double borderRadius;
  final ShadowStyle shadowStyle;
  final Border? border;
  final VoidCallback? onTap;

  const BentoCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderRadius = AppTheme.radiusXl, // default soft roundness
    this.shadowStyle = ShadowStyle.light,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    List<BoxShadow> getShadows() {
      switch (shadowStyle) {
        case ShadowStyle.none:
          return [];
        case ShadowStyle.light:
          return AppTheme.hardShadowLight;
        case ShadowStyle.heavy:
          return AppTheme.hardShadowHeavy;
        case ShadowStyle.button:
          return AppTheme.hardShadowButton;
      }
    }

    final boxBorder = border ?? AppTheme.cardBorder;

    final card = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: boxBorder,
        boxShadow: getShadows(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppTheme.radiusMd),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      );
    }

    return card;
  }
}

