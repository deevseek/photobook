import 'package:flutter/foundation.dart';
import '../../../data/models/auth_customer_model.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository}) : _repository = repository ?? AuthRepository();
  final AuthRepository _repository;
  AuthCustomerModel? user;
  bool loading = false;
  String? error;
  bool initialized = false;

  Future<void> bootstrap() async {
    loading = true; notifyListeners();
    try { user = await _repository.me(); error = null; } catch (_) { user = null; }
    loading = false; initialized = true; notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    loading = true; error = null; notifyListeners();
    try {
      final logged = await _repository.loginWithGoogle();
      if (logged == null) { error = 'Login dibatalkan.'; return false; }
      user = logged; return true;
    } catch (e) { error = e.toString().replaceFirst('Exception: ', ''); return false; }
    finally { loading = false; notifyListeners(); }
  }

  Future<void> logout() async { await _repository.logout(); user = null; notifyListeners(); }
}
