import 'dart:math';
import 'package:flutter/material.dart';

class GasBubbleBackground extends StatefulWidget {
  const GasBubbleBackground({Key? key}) : super(key: key);

  @override
  _GasBubbleBackgroundState createState() => _GasBubbleBackgroundState();
}

class _GasBubbleBackgroundState extends State<GasBubbleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random random = Random();

  late List<Offset> positions;
  late List<double> sizes;
  late List<Offset> directions;
  final int bubbleCount = 30;

  @override
  void initState() {
    super.initState();

    _controller =
    AnimationController(vsync: this, duration: Duration(seconds: 30))
      ..repeat();

    positions = List.generate(
        bubbleCount, (_) => Offset(random.nextDouble(), random.nextDouble()));

    // Sizes: mix small (5–12) and medium (15–30)
    sizes = List.generate(
        bubbleCount,
            (_) =>
        random.nextBool()
            ? random.nextDouble() * 25 + 5
            : random.nextDouble() * 37 + 15);

    // Random directions: x and y velocities (drifting)
    directions = List.generate(
        bubbleCount,
            (_) => Offset(random.nextDouble() * 0.002 - 0.001,
            random.nextDouble() * 0.002 - 0.002));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Update positions
        for (int i = 0; i < bubbleCount; i++) {
          double dx = positions[i].dx + directions[i].dx;
          double dy = positions[i].dy + directions[i].dy;

          // Wrap around edges
          if (dx > 1) dx = 0;
          if (dx < 0) dx = 1;
          if (dy > 1) dy = 0;
          if (dy < 0) dy = 1;

          positions[i] = Offset(dx, dy);
        }

        return CustomPaint(
          painter: GasBubblePainter(
            positions: positions,
            sizes: sizes,
          ),
        );
      },
    );
  }
}

class GasBubblePainter extends CustomPainter {
  final List<Offset> positions;
  final List<double> sizes;

  GasBubblePainter({required this.positions, required this.sizes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.20)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < positions.length; i++) {
      final pos = positions[i];
      canvas.drawCircle(
        Offset(pos.dx * size.width, pos.dy * size.height),
        sizes[i],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
