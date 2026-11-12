// lib/widgets/favorite_button.dart
import 'package:flutter/material.dart';

import '../state/favorites.dart';

/// Дуртайд нэмэх / хасах зүрхэн товч. Төлөв өөрчлөгдөхөд өөрөө дахин зурагдана.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.placeId, this.compact = false});

  final String placeId;

  /// Карт дээрх жижиг хувилбар.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder<Set<String>>(
      valueListenable: favorites,
      builder: (context, ids, _) {
        final selected = ids.contains(placeId);
        return IconButton.filledTonal(
          visualDensity: compact ? VisualDensity.compact : null,
          tooltip: selected ? 'Дуртайгаас хасах' : 'Дуртайд нэмэх',
          onPressed: () => toggleFavorite(placeId),
          style: IconButton.styleFrom(
            backgroundColor: colors.surface.withValues(alpha: 0.92),
          ),
          icon: Icon(
            selected ? Icons.favorite : Icons.favorite_border,
            color: selected ? colors.error : colors.onSurface,
            size: compact ? 20 : null,
          ),
        );
      },
    );
  }
}
