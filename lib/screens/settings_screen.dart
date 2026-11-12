// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/auth_service.dart';

/// Тохиргоо: хэрэглэгчийн мэдээлэл, нууц үг солих, системээс гарах.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Системээс гарах уу?'),
        content: const Text('Дахин ашиглахын тулд нэвтрэх шаардлагатай.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Болих'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Гарах'),
          ),
        ],
      ),
    );
    if (ok == true) auth.logout(); // router нэвтрэх дэлгэц рүү шилжүүлнэ
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Тохиргоо')),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(auth.email ?? 'Хэрэглэгч'),
            subtitle: const Text('Нэвтэрсэн хэрэглэгч'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Нууц үг солих'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/password'),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: colors.error),
            title: Text('Системээс гарах',
                style: TextStyle(color: colors.error)),
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }
}
