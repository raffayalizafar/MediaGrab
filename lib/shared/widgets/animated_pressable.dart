import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Interactive wrapper providing a tactile spring bounce and scale micro-interaction on press.
class AnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final Duration duration;
  final Curve curve;
  final bool enableHaptic;
  final BorderRadius? borderRadius;

  const AnimatedPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.95,
    this.duration = const Duration(milliseconds: 120),
    this.curve = Curves.easeOutCubic,
    this.enableHaptic = true,
    this.borderRadius,
  });

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!_isPressed) {
      setState(() => _isPressed = true);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasHandler = widget.onTap != null || widget.onLongPress != null;

    final scaledChild = AnimatedScale(
      scale: _isPressed ? widget.pressedScale : 1.0,
      duration: widget.duration,
      curve: widget.curve,
      child: widget.child,
    );

    if (hasHandler) {
      return GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: () {
          if (widget.enableHaptic) {
            HapticFeedback.lightImpact();
          }
          widget.onTap?.call();
        },
        onLongPress: () {
          if (widget.enableHaptic) {
            HapticFeedback.mediumImpact();
          }
          widget.onLongPress?.call();
        },
        behavior: HitTestBehavior.opaque,
        child: scaledChild,
      );
    }

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      behavior: HitTestBehavior.translucent,
      child: scaledChild,
    );
  }
}
