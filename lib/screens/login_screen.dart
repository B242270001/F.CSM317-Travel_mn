// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/auth_service.dart';

/// Арын дэвсгэр: сэдвийн өнгөнөөс (primary → tertiary) үүсгэсэн градиент.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose(); // controller-уудыг цэвэрлэнэ
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await auth.login(_email.text.trim(), _password.text);
    if (!mounted) return; // дэлгэц хаагдсан бол зогсоно
    setState(() => _loading = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('И-мэйл эсвэл нууц үг буруу')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // Градиент бараан бол статус мөрийн дүрсийг цагаан болгоно
    final darkBackground =
        ThemeData.estimateBrightnessForColor(scheme.primary) ==
            Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: darkBackground
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
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
                  // Том дэлгэцэд формыг 420 dp-ээс өргөн болгохгүй
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.travel_explore,
                        size: 72,
                        color: scheme.onPrimary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Аяллын газрууд',
                        style: text.headlineMedium?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Монголын үзэсгэлэнт газруудыг нээ',
                        style: text.bodyLarge?.copyWith(
                          color: scheme.onPrimary.withAlpha(220),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                          child: _buildForm(text),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(TextTheme text) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Нэвтрэх', style: text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(
              labelText: 'И-мэйл',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (v) => (v == null || !v.trim().contains('@'))
                ? 'Зөв и-мэйл оруулна уу'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Нууц үг',
              helperText: 'Анхны нууц үг: ${AuthService.defaultPassword}',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                tooltip: _obscure ? 'Харуулах' : 'Нуух',
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => (v == null || v.length < 8)
                ? 'Хамгийн багадаа 8 тэмдэгт'
                : null,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit, // давхар дарахаас сэргийлнэ
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      semanticsLabel: 'Нэвтэрч байна',
                    ),
                  )
                : const Text('Нэвтрэх'),
          ),
        ],
      ),
    );
  }
}
