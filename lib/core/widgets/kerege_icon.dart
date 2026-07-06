import 'package:flutter/material.dart';

/// KeregeSystem brand mark — pos-register variant (blue · tenge).
///
/// Asset bundled at `assets/brand/app_icon.png` (sourced from
/// `pos-docs/icons/png/pos-register-1024.png`). Renders crisp at any
/// size; defaults to 40×40 to match the existing sidebar slot.
class KeregeIcon extends StatelessWidget {
  const KeregeIcon({
    super.key,
    this.size = 40,
    this.borderRadius = 10,
  });

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 3.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        'assets/brand/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        // Cache the decoded bitmap at the rendered size — at 40 px there's
        // no point holding the 1024×1024 source in memory.
        cacheWidth: (size * dpr).toInt(),
      ),
    );
  }
}
