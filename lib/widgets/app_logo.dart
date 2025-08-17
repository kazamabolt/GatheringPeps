import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showShadow;
  final BorderRadius? borderRadius;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showShadow = true,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(12), // Fixed border radius
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  blurRadius: size * 0.1,
                  offset: Offset(0, size * 0.05),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(12), // Fixed border radius
        child: Image.asset(
          'assets/images/Gathering_peps Logo.png',
          fit: BoxFit.contain, // Changed to contain to show full logo
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: borderRadius ?? BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.group,
                size: size * 0.5,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}

class AppLogoWithText extends StatelessWidget {
  final double logoSize;
  final String? title;
  final String? subtitle;
  final bool showShadow;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const AppLogoWithText({
    super.key,
    this.logoSize = 80,
    this.title,
    this.subtitle,
    this.showShadow = true,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppLogo(
          size: logoSize,
          showShadow: showShadow,
        ),
        if (title != null) ...[
          SizedBox(height: logoSize * 0.25),
          Text(
            title!,
            style: titleStyle ??
                Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
        if (subtitle != null) ...[
          SizedBox(height: logoSize * 0.1),
          Text(
            subtitle!,
            style: subtitleStyle ??
                Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
