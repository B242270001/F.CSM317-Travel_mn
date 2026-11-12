// lib/widgets/star_rating.dart
import 'dart:math';

import 'package:flutter/material.dart';

class StarPainter extends CustomPainter {
  StarPainter({required this.fill, required this.color, required this.empty});

  final double fill;
  final Color color;
  final Color empty;

  Path _star(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = size.width / 2;
    final inner = outer * 0.45;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner; // гадна, дотор оройг ээлжилнэ
      final a = -pi / 2 + i * pi / 5;
      final x = cx + r * cos(a);
      final y = cy + r * sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _star(size);
    canvas.drawPath(path, Paint()..color = empty);
    if (fill <= 0) return;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * fill, size.height));
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(StarPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.color != color ||
      oldDelegate.empty != empty;
}

/// 5 одоор үнэлгээ харуулна (бутархай хэсгийг хэсэгчлэн будна).
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 20});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final empty = Theme.of(context).colorScheme.outlineVariant;
    return Semantics(
      label: 'Үнэлгээ ${rating.toStringAsFixed(1)}',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 5; i++)
              CustomPaint(
                size: Size(size, size),
                painter: StarPainter(
                  fill: (rating - i).clamp(0.0, 1.0),
                  color: Colors.amber,
                  empty: empty,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
