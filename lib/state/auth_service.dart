// lib/state/auth_service.dart
import 'package:flutter/foundation.dart';

import '../db/app_db.dart';

/// Нэвтрэлтийн төлөв. Бүртгүүлсэн хэрэглэгчид локал өгөгдлийн санд
/// хадгалагдана. Бүртгэлгүй и-мэйлээр анхны нууц үгээр (зочин) нэвтэрч болно.
///
/// Анхаар: сургалтын апп тул нууц үгийг энгийн текстээр хадгалж байна.
/// Бодит апп-д сервер талд hash хийж хадгална.
class AuthService extends ChangeNotifier {
  static const defaultPassword = 'Mobile317';

  bool _loggedIn = false;
  String? _email;
  String? _name;
  String _guestPassword = defaultPassword; // бүртгэлгүй хэрэглэгчид

  bool get loggedIn => _loggedIn;
  String? get email => _email;

  /// Мэндчилгээнд харуулах нэр.
  String get displayName => _name ?? _email?.split('@').first ?? 'Аялагч';

  Map<String, dynamic> get _users => AppDb.readMap('users');

  Map<String, dynamic>? _user(String email) =>
      (_users[email.toLowerCase()] as Map?)?.cast<String, dynamic>();

  Future<bool> login(String email, String password) async {
    // сервертэй холбогдохыг 1 секундын хүлээлтээр дуурайлгана
    await Future<void>.delayed(const Duration(seconds: 1));
    final user = _user(email);
    _loggedIn = user != null
        ? password == user['password']
        : password == _guestPassword;
    _email = _loggedIn ? email : null;
    final savedName = user == null ? null : user['name'] as String?;
    _name = _loggedIn ? savedName : null;
    notifyListeners(); // router-ийн redirect дахин ажиллана
    return _loggedIn;
  }

  /// Шинэ хэрэглэгч бүртгэнэ. И-мэйл бүртгэлтэй бол алдааны мессеж буцаана.
  Future<String?> register(String name, String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final key = email.toLowerCase();
    if (_users.containsKey(key)) return 'Энэ и-мэйл бүртгэлтэй байна';
    await AppDb.write('users', {
      ..._users,
      key: {'name': name, 'password': password},
    });
    _loggedIn = true;
    _email = email;
    _name = name;
    notifyListeners();
    return null;
  }

  /// Нууц үг солих. Одоогийн нууц үг буруу бол false буцаана.
  /// Нэвтрэлтийн төлөв өөрчлөгдөхгүй тул notifyListeners дуудахгүй.
  Future<bool> changePassword(String current, String next) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final email = _email;
    final user = email == null ? null : _user(email);
    if (user == null) {
      if (current != _guestPassword) return false;
      _guestPassword = next;
      return true;
    }
    if (current != user['password']) return false;
    await AppDb.write('users', {
      ..._users,
      email!.toLowerCase(): {...user, 'password': next},
    });
    return true;
  }

  /// Системээс гарах.
  void logout() {
    _loggedIn = false;
    _email = null;
    _name = null;
    notifyListeners();
  }
}

/// Апп даяар ашиглах нэг AuthService.
final auth = AuthService();
