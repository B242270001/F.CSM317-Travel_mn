// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/password_field.dart';

/// «Бүртгүүлэх»: нэр, и-мэйл, нууц үгээр шинэ хэрэглэгч үүсгэнэ.
/// Амжилттай бол шууд нэвтэрч, router нүүр дэлгэц рүү шилжүүлнэ.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final error = await auth.register(
      _name.text.trim(),
      _email.text.trim(),
      _password.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primary, scheme.secondary, scheme.tertiary],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Бүртгэл үүсгэх',
                      style: text.headlineMedium?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _name,
                                decoration: const InputDecoration(
                                  labelText: 'Нэр',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                validator: (v) =>
                                    (v == null || v.trim().length < 2)
                                    ? 'Нэрээ оруулна уу'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _email,
                                decoration: const InputDecoration(
                                  labelText: 'И-мэйл',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (v) =>
                                    (v == null || !v.trim().contains('@'))
                                    ? 'Зөв и-мэйл оруулна уу'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              PasswordField(
                                controller: _password,
                                label: 'Нууц үг',
                                helperText:
                                    '8+ тэмдэгт, дор хаяж нэг үсэг ба нэг тоо',
                                validator: validateNewPassword,
                              ),
                              const SizedBox(height: 12),
                              PasswordField(
                                controller: _confirm,
                                label: 'Нууц үгээ давтах',
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                validator: (v) => v != _password.text
                                    ? 'Нууц үг таарахгүй байна'
                                    : null,
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
                                          semanticsLabel: 'Бүртгэж байна',
                                        ),
                                      )
                                    : const Text('Бүртгүүлэх'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Бүртгэлтэй юу? Нэвтрэх',
                        style: TextStyle(color: scheme.onPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
