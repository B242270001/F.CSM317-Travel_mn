// lib/state/auth_service.dart
import 'package:flutter/foundation.dart';

/// Нэвтрэлтийн төлөв. Өгөгдөл санах ойд хадгалагдах тул апп дахин эхлэхэд
/// нууц үг анхны утгандаа буцна.
class AuthService extends ChangeNotifier {
  static const defaultPassword = 'Mobile317';

  bool _loggedIn = false;
  String? _email;
  String _password = defaultPassword; // жишээ: санах ойд хадгална

  bool get loggedIn => _loggedIn;
  String? get email => _email; // “Тохиргоо” дэлгэцэд харуулна

  Future<bool> login(String email, String password) async {
    // сервертэй холбогдохыг 1 секундын хүлээлтээр дуурайлгана
    await Future<void>.delayed(const Duration(seconds: 1));
    _loggedIn = password == _password; // жишээ шалгалт
    _email = _loggedIn ? email : null;
    notifyListeners(); // router-ийн redirect дахин ажиллана
    return _loggedIn;
  }

  /// Нууц үг солих. Одоогийн нууц үг буруу бол false буцаана.
  /// Нэвтрэлтийн төлөв өөрчлөгдөхгүй тул notifyListeners дуудахгүй.
  Future<bool> changePassword(String current, String next) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (current != _password) return false;
    _password = next;
    return true;
  }

  /// Системээс гарах.
  void logout() {
    _loggedIn = false;
    _email = null;
    notifyListeners();
  }
}

/// Апп даяар ашиглах нэг AuthService.
final auth = AuthService();
