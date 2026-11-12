// lib/screens/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/password_field.dart';

/// Тохиргоо → Нууц үг солих. Одоогийн, шинэ, давтан нууц үгтэй форм.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentKey = GlobalKey<FormFieldState<String>>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  /// Серверээс ирсэн алдаа (одоогийн нууц үг буруу). Validator-оор харуулна.
  String? _currentError;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _currentError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await auth.changePassword(_current.text, _next.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      _currentError = 'Одоогийн нууц үг буруу байна';
      _formKey.currentState!.validate(); // алдааг талбар дээр харуулна
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Нууц үг амжилттай солигдлоо')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Нууц үг солих')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            PasswordField(
              controller: _current,
              label: 'Одоогийн нууц үг',
              autofillHints: const [AutofillHints.password],
              // Шинээр бичиж эхлэхэд серверийн алдааг арилгана
              fieldKey: _currentKey,
              onChanged: (_) {
                if (_currentError != null) {
                  _currentError = null;
                  _currentKey.currentState?.validate(); // алдааг арилгана
                }
              },
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Одоогийн нууц үгээ оруулна уу';
                }
                return _currentError;
              },
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _next,
              label: 'Шинэ нууц үг',
              helperText: '8+ тэмдэгт, дор хаяж нэг үсэг ба нэг тоо',
              autofillHints: const [AutofillHints.newPassword],
              // Хүчний үзүүлэлтийг бичих бүрт шинэчилнэ
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final error = validateNewPassword(v);
                if (error != null) return error;
                if (v == _current.text) {
                  return 'Шинэ нууц үг одоогийнхоос өөр байх ёстой';
                }
                return null;
              },
            ),
            if (_next.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _StrengthMeter(strength: passwordStrength(_next.text)),
            ],
            const SizedBox(height: 12),
            PasswordField(
              controller: _confirm,
              label: 'Шинэ нууц үгээ давтах',
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _submit(),
              validator: (v) =>
                  v != _next.text ? 'Нууц үг таарахгүй байна' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: 'Хадгалж байна',
                      ),
                    )
                  : const Text('Нууц үг солих'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Нууц үгийн хүч: сул (улаан) / дунд (улбар шар) / хүчтэй (ногоон).
class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength});

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    final color = switch (strength) {
      PasswordStrength.weak => Colors.red,
      PasswordStrength.medium => Colors.orange,
      PasswordStrength.strong => Colors.green,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strength.value,
            minHeight: 6,
            color: color,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            semanticsLabel: 'Нууц үгийн хүч',
            semanticsValue: strength.label,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Нууц үгийн хүч: ${strength.label}',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
