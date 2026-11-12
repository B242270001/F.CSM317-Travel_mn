// lib/utils/validators.dart

/// Нууц үгийн үндсэн шаардлага: 8+ тэмдэгт, дор хаяж нэг үсэг ба нэг тоо.
String? validateNewPassword(String? v) {
  final p = v ?? '';
  if (p.length < 8) return 'Хамгийн багадаа 8 тэмдэгт';
  if (!RegExp(r'\d').hasMatch(p)) return 'Дор хаяж нэг тоо оруулна уу';
  // \p{L} — дурын хэлний үсэг (латин, кирилл ...)
  if (!RegExp(r'\p{L}', unicode: true).hasMatch(p)) {
    return 'Дор хаяж нэг үсэг оруулна уу';
  }
  if (p.contains(' ')) return 'Хоосон зай оруулж болохгүй';
  return null;
}

/// Нууц үгийн хүч.
enum PasswordStrength {
  weak('Сул', 1 / 3),
  medium('Дунд', 2 / 3),
  strong('Хүчтэй', 1);

  const PasswordStrength(this.label, this.value);

  final String label;

  /// LinearProgressIndicator-т өгөх утга (0–1).
  final double value;
}

/// Нууц үгийн хүчийг урт ба тэмдэгтийн төрлөөр үнэлнэ.
/// Оноо: 8+ урт, 12+ урт, жижиг үсэг, том үсэг, тоо, тусгай тэмдэгт.
PasswordStrength passwordStrength(String p) {
  var score = 0;
  if (p.length >= 8) score++;
  if (p.length >= 12) score++;
  if (RegExp(r'\p{Ll}', unicode: true).hasMatch(p)) score++;
  if (RegExp(r'\p{Lu}', unicode: true).hasMatch(p)) score++;
  if (RegExp(r'\d').hasMatch(p)) score++;
  if (RegExp(r'[^\p{L}\d\s]', unicode: true).hasMatch(p)) score++;

  // Богино нууц үг ямар ч тэмдэгттэй байсан сул хэвээр
  if (p.length < 8 || score <= 3) return PasswordStrength.weak;
  if (score <= 4) return PasswordStrength.medium;
  return PasswordStrength.strong;
}
