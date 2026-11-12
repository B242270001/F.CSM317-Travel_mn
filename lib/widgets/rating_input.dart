// lib/widgets/rating_input.dart
import 'package:flutter/material.dart';

/// Дарж үнэлгээ өгөх 5 од. [value] = 0 бол хараахан үнэлээгүй.
class RatingInput extends StatelessWidget {
  const RatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 36,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final empty = Theme.of(context).colorScheme.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            iconSize: size,
            tooltip: '$i од',
            isSelected: i <= value,
            icon: Icon(Icons.star_border, color: empty),
            selectedIcon: const Icon(Icons.star, color: Colors.amber),
            onPressed: () => onChanged(i),
          ),
      ],
    );
  }
}
