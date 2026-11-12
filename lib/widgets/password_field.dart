// lib/widgets/password_field.dart
import 'package:flutter/material.dart';

/// Харуулах/нуух товчтой нууц үгийн талбар.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.fieldKey,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;

  /// Талбарыг дангаар нь дахин шалгах (validate) шаардлагатай үед.
  final GlobalKey<FormFieldState<String>>? fieldKey;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: widget.fieldKey,
      controller: widget.controller,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        helperMaxLines: 2,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          tooltip: _obscure ? 'Харуулах' : 'Нуух',
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
