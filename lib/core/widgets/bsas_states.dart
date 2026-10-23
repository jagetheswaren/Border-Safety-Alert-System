import 'package:flutter/material.dart';
import '../theme/app_motion.dart';
import '../theme/bsas_colors.dart';
import 'bsas_slide_button.dart';

/// Clean tactical Empty State.
class BSASEmptyState extends StatelessWidget {
  const BSASEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: BsasColors.darkSurface,
                shape: BoxShape.circle,
                border: Border.all(color: BsasColors.darkBorder),
              ),
              child: Icon(icon, size: 28, color: BsasColors.textLightMuted),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: BsasColors.textLightPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: BsasColors.textLightSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              BSASSlideButton(
                label: actionLabel!,
                isFullWidth: false,
                height: 40,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Actionable, informative Error State.
/// Shows what happened, what still works, and what action to take.
class BSASErrorState extends StatelessWidget {
  const BSASErrorState({
    super.key,
    required this.title,
    required this.whatHappened,
    required this.whatStillWorks,
    this.retryLabel = 'RETRY CONNECTION',
    this.onRetry,
  });

  final String title;
  final String whatHappened;
  final String whatStillWorks;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: BsasColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BsasColors.warningOrange.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: BsasColors.warningOrange,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: BsasColors.textLightPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            whatHappened,
            style: const TextStyle(
              color: BsasColors.textLightSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: BsasColors.darkBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BsasColors.darkBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: BsasColors.safeGreen,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Operational: $whatStillWorks',
                    style: const TextStyle(
                      color: BsasColors.safeGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            BSASSlideButton(
              label: retryLabel,
              primaryColor: BsasColors.warningOrange,
              height: 40,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmering skeleton loader for card placeholders.
class BSASSkeleton extends StatefulWidget {
  const BSASSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12.0,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<BSASSkeleton> createState() => _BSASSkeletonState();
}

class _BSASSkeletonState extends State<BSASSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.isReducedMotion(context)) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: BsasColors.darkSurface,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final alpha = 0.35 + (_anim.value * 0.25);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: BsasColors.darkSurface.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: BsasColors.darkBorder.withValues(alpha: alpha),
            ),
          ),
        );
      },
    );
  }
}
