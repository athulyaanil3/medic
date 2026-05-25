import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MediBackground extends StatelessWidget {
  const MediBackground({
    super.key,
    required this.child,
    this.pad = true,
    this.showBlobs = true,
  });

  final Widget child;
  final bool pad;
  final bool showBlobs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.scaffoldGradient(context),
      ),

      child: Stack(
        children: [
          /// Decorative blobs
          if (showBlobs) ...[
            Positioned(
              top: -80,
              right: -40,
              child: _Blob(
                size: 220,
                color: AppTheme.mint.withValues(
                  alpha: 0.35,
                ),
              ),
            ),

            Positioned(
              top: 120,
              left: -60,
              child: _Blob(
                size: 160,
                color: AppTheme.tealLight.withValues(
                  alpha: 0.18,
                ),
              ),
            ),

            Positioned(
              bottom: 80,
              right: -30,
              child: _Blob(
                size: 140,
                color: AppTheme.accentCoral.withValues(
                  alpha: 0.12,
                ),
              ),
            ),
          ],

          /// Main content
          SafeArea(
            child: SizedBox.expand(
              child: pad
                  ? Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: child,
              )
                  : child,
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,

        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}