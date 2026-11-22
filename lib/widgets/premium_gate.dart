// lib/widgets/premium_gate.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/subscription.dart';

/// Premium шаардлагатай үйлдлийн өмнө дуудна. Premium бол шууд true;
/// үгүй бол тайлбар харуулж, хэрэглэгч хүсвэл захиалгын дэлгэц рүү
/// шилжүүлнэ. Буцаж ирэхэд Premium болсон эсэхийг буцаана.
Future<bool> requirePremium(BuildContext context, String reason) async {
  if (subscription.isPremium) return true;
  final go = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.workspace_premium, color: Colors.amber, size: 40),
      title: const Text('Premium шаардлагатай'),
      content: Text(reason),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Дараа'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Premium авах'),
        ),
      ],
    ),
  );
  if (go != true || !context.mounted) return false;
  await context.push('/premium');
  return subscription.isPremium;
}

/// «PREMIUM» гэсэн жижиг тэмдэг.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 9,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium,
            size: compact ? 12 : 14,
            color: Colors.black87,
          ),
          const SizedBox(width: 3),
          Text(
            'PREMIUM',
            style: TextStyle(
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
