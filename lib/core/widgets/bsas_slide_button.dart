import 'package:flutter/material.dart';
import '../theme/app_motion.dart';
import '../theme/bsas_colors.dart';

enum BSASSlideButtonState { idle, loading, success }

/// Flutter-native adaptation of the React Bits SlideAction / SlideButton.
///
/// Features:
/// - Smooth touch-press scale compression (0.98x)
/// - Left-to-right horizontal sliding accent gradient fill
/// - State morphing: idle -> loading (spinner) -> success (checkmark)
class BSASSlideButton extends StatefulWidget {
  const BSASSlideButton({
    super.key,
    required this.label,
    this.loadingLabel = 'PROCESSING...',
    this.successLabel = 'CONFIRMED ✓',
    this.state = BSASSlideButtonState.idle,
    this.onPressed,
    this.icon,
    this.primaryColor = BsasColors.primaryBlue,
    this.height = 48.0,
    this.isFullWidth = true,
  });

  final String label;
  final String loadingLabel;
  final String successLabel;
  final BSASSlideButtonState state;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color primaryColor;
  final double height;
  final bool isFullWidth;

  @override
  State<BSASSlideButton> createState() => _BSASSlideButtonState();
}

class _BSASSlideButtonState extends State<BSASSlideButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReducedMotion(context);
    final isInteractive = widget.state == BSASSlideButtonState.idle && widget.onPressed != null;

    final scale = (_isPressed && !reduced) ? 0.975 : 1.0;

    Widget content;
    switch (widget.state) {
      case BSASSlideButtonState.loading:
        content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.loadingLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        );
        break;
      case BSASSlideButtonState.success:
        content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 8),
            Text(
              widget.successLabel,
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        );
        break;
      case BSASSlideButtonState.idle:
        content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              widget.icon!,
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 16, color: Colors.white70),
          ],
        );
    }

    return AnimatedScale(
      scale: scale,
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      child: GestureDetector(
        onTapDown: isInteractive ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isInteractive
            ? (_) {
                setState(() => _isPressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: isInteractive ? () => setState(() => _isPressed = false) : null,
        child: Container(
          height: widget.height,
          width: widget.isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: widget.state == BSASSlideButtonState.success
                ? const Color(0xFF064E3B)
                : widget.primaryColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.state == BSASSlideButtonState.success
                  ? const Color(0xFF10B981).withValues(alpha: 0.6)
                  : BsasColors.primaryBlueLight.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: AppMotion.fast,
            child: content,
          ),
        ),
      ),
    );
  }
}
