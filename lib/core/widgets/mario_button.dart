import 'package:flutter/material.dart';

import '../../theme/mario_theme.dart';
import '../accessibility/a11y_controller.dart';

/// Big, chunky Mario-style button — bold outline, hard drop shadow, no fades.
///
/// Honors the a11y "larger targets" preference for hit-zone sizing.
class MarioButton extends StatefulWidget {
  const MarioButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = MarioColors.marioRed,
    this.foregroundColor = MarioColors.cloudWhite,
    this.icon,
    this.expand = false,
    this.compact = false,
    required this.a11y,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color foregroundColor;
  final Widget? icon;
  final bool expand;
  final bool compact;
  final A11yController a11y;

  @override
  State<MarioButton> createState() => _MarioButtonState();
}

class _MarioButtonState extends State<MarioButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final h = widget.compact
        ? widget.a11y.minTapTarget
        : widget.a11y.minTapTarget + 12;
    final shadow = widget.a11y.highContrast ? 6.0 : 4.0;

    final child = Semantics(
      button: true,
      enabled: !disabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          curve: Curves.linear,
          height: h,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? MarioSpacing.sm : MarioSpacing.md,
          ),
          transform: Matrix4.translationValues(0, _pressed ? shadow : 0, 0),
          decoration: BoxDecoration(
            color:
                disabled ? widget.color.withValues(alpha: 0.45) : widget.color,
            borderRadius: BorderRadius.circular(MarioRadius.md),
            border: Border.all(color: MarioColors.bowserBlack, width: 3),
            boxShadow: _pressed || disabled
                ? const []
                : [
                    BoxShadow(
                      color: MarioColors.bowserBlack,
                      offset: Offset(0, shadow),
                      spreadRadius: 0,
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                IconTheme.merge(
                  data: IconThemeData(color: widget.foregroundColor, size: 22),
                  child: widget.icon!,
                ),
                const SizedBox(width: MarioSpacing.xs),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: widget.foregroundColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return widget.expand
        ? SizedBox(width: double.infinity, child: child)
        : child;
  }
}
