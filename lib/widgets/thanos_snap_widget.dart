import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A widget that captures its child as an image and shatters it into
/// dissolving pixel blocks — the "Thanos Snap" effect.
///
/// Usage:
///   final snapKey = GlobalKey<ThanosSnapWidgetState>();
///   ThanosSnapWidget(key: snapKey, child: YourScreen());
///   // Trigger: snapKey.currentState?.snap();
class ThanosSnapWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSnapComplete;
  final Duration duration;

  const ThanosSnapWidget({
    super.key,
    required this.child,
    this.onSnapComplete,
    this.duration = const Duration(milliseconds: 1800),
  });

  @override
  State<ThanosSnapWidget> createState() => ThanosSnapWidgetState();
}

class ThanosSnapWidgetState extends State<ThanosSnapWidget>
    with SingleTickerProviderStateMixin {
  final _boundaryKey = GlobalKey();
  AnimationController? _controller;
  ui.Image? _capturedImage;
  List<_Particle>? _particles;
  bool _snapping = false;

  /// Call this to trigger the snap effect.
  Future<void> snap() async {
    if (_snapping) return;

    // 1. Capture the child widget as an image
    final boundary = _boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 1.0);
    final width = image.width;
    final height = image.height;

    // 2. Generate particles (grid of small blocks)
    const blockSize = 6;
    final rng = Random();
    final particles = <_Particle>[];

    for (int y = 0; y < height; y += blockSize) {
      for (int x = 0; x < width; x += blockSize) {
        final bw = min(blockSize, width - x);
        final bh = min(blockSize, height - y);

        // Stagger: particles on the right dissolve first
        final normalizedX = x / width;
        final delay = normalizedX * 0.5 + rng.nextDouble() * 0.2;

        particles.add(_Particle(
          srcRect: Rect.fromLTWH(
              x.toDouble(), y.toDouble(), bw.toDouble(), bh.toDouble()),
          dx: (rng.nextDouble() - 0.3) * 80,
          dy: -(rng.nextDouble() * 60 + 20),
          rotation: (rng.nextDouble() - 0.5) * 2,
          delay: delay.clamp(0.0, 0.7),
        ));
      }
    }

    // 3. Animate
    _controller = AnimationController(vsync: this, duration: widget.duration);

    setState(() {
      _capturedImage = image;
      _particles = particles;
      _snapping = true;
    });

    _controller!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onSnapComplete?.call();
      }
    });

    _controller!.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _capturedImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_snapping && _capturedImage != null && _particles != null) {
      return AnimatedBuilder(
        animation: _controller!,
        builder: (context, _) {
          return CustomPaint(
            size: Size(
              _capturedImage!.width.toDouble(),
              _capturedImage!.height.toDouble(),
            ),
            painter: _SnapPainter(
              image: _capturedImage!,
              particles: _particles!,
              progress: _controller!.value,
            ),
          );
        },
      );
    }

    return RepaintBoundary(
      key: _boundaryKey,
      child: widget.child,
    );
  }
}

class _Particle {
  final Rect srcRect;
  final double dx; // horizontal drift
  final double dy; // vertical drift (negative = upward)
  final double rotation;
  final double delay; // 0..0.7 — when this particle starts dissolving

  _Particle({
    required this.srcRect,
    required this.dx,
    required this.dy,
    required this.rotation,
    required this.delay,
  });
}

class _SnapPainter extends CustomPainter {
  final ui.Image image;
  final List<_Particle> particles;
  final double progress; // 0..1

  _SnapPainter({
    required this.image,
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Calculate local progress for this particle
      final effectiveDuration = 1.0 - p.delay;
      if (effectiveDuration <= 0) continue;
      final localProgress =
          ((progress - p.delay) / effectiveDuration).clamp(0.0, 1.0);

      if (localProgress <= 0.0) {
        // Not started yet — draw in place
        canvas.drawImageRect(
          image,
          p.srcRect,
          p.srcRect,
          Paint(),
        );
        continue;
      }

      // Eased progress
      final ease = Curves.easeIn.transform(localProgress);
      final opacity = (1.0 - localProgress).clamp(0.0, 1.0);

      if (opacity <= 0.01) continue;

      final dx = p.srcRect.left + p.dx * ease;
      final dy = p.srcRect.top + p.dy * ease;

      canvas.save();
      canvas.translate(
          dx + p.srcRect.width / 2, dy + p.srcRect.height / 2);
      canvas.rotate(p.rotation * ease);
      canvas.translate(-p.srcRect.width / 2, -p.srcRect.height / 2);

      canvas.drawImageRect(
        image,
        p.srcRect,
        Rect.fromLTWH(0, 0, p.srcRect.width, p.srcRect.height),
        Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SnapPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
