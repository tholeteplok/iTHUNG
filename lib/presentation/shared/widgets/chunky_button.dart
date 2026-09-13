import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Tombol interaktif bergaya "Cozy Tactile 3D".
///
/// Memiliki efek visual tactile fisik:
/// Memiliki 3D bottom-lip tebal 4px. Saat ditekan, tombol turun sejauh 4px
/// dan shadow merapat ke permukaan memberi kepuasan taktil seperti tombol mainan empuk.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor = AppTheme.colorVanillaCard,
    this.borderColor,
    this.shadowColor,
    this.borderRadius = AppTokens.radiusButton,
    this.borderWidth = AppTokens.borderWidthDefault,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.width,
    this.height,
    this.rotation = 0.0,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color backgroundColor;
  final Color? borderColor;
  final Color? shadowColor;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final double rotation;
  final bool enabled;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (!widget.enabled || widget.onPressed == null) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.enabled || widget.onPressed == null) return;
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (!widget.enabled || widget.onPressed == null) return;
    setState(() => _isPressed = false);
  }

  Color _computeDarkerLip(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    const shadowOffset = 4.0;
    final isPressed = _isPressed;

    final isWarmSurface = widget.backgroundColor == Colors.white ||
        widget.backgroundColor == AppTheme.colorVanillaCard ||
        widget.backgroundColor == AppTheme.colorWoodPlank;

    final effectiveBorderColor = widget.borderColor ??
        (isWarmSurface
            ? AppTheme.colorWoodMedium
            : _computeDarkerLip(widget.backgroundColor));

    final effectiveShadowColor = widget.shadowColor ??
        (isWarmSurface
            ? AppTheme.colorWoodDark
            : _computeDarkerLip(widget.backgroundColor));

    Widget button = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: AppTokens.buttonPressDuration,
        curve: Curves.easeInOut,
        width: widget.width,
        height: widget.height,
        constraints: const BoxConstraints(
          minHeight: AppTokens.minTapTarget,
          minWidth: AppTokens.minTapTarget,
        ),
        transform: isPressed
            ? Matrix4.translationValues(0, shadowOffset, 0)
            : Matrix4.identity(),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.enabled
              ? widget.backgroundColor
              : widget.backgroundColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: effectiveBorderColor,
            width: widget.borderWidth,
          ),
          boxShadow: isPressed
              ? ChunkyShadow.pressed
              : ChunkyShadow.button(effectiveShadowColor),
        ),
        child: Center(child: widget.child),
      ),
    );

    if (widget.rotation != 0.0) {
      button = Transform.rotate(angle: widget.rotation, child: button);
    }

    return button;
  }
}
