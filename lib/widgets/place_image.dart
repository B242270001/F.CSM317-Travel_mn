// lib/widgets/place_image.dart
import 'package:flutter/material.dart';

/// Газрын зураг. Зураггүй эсвэл ачаалж чадаагүй үед дүрс бүхий дэвсгэр харуулна.
class PlaceImage extends StatelessWidget {
  const PlaceImage({super.key, required this.image, this.semanticLabel});

  final ImageProvider? image;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          size: 48,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
    final provider = image;
    if (provider == null) return placeholder;
    return Image(
      image: provider,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      semanticLabel: semanticLabel,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
