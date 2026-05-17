import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';
import '../../../data/models/auth_customer_model.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository, TokenStorage? tokenStorage})
      : _repository = repository ?? AuthRepository(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;

  AuthCustomerModel? user;
  bool loading = false;
  String? error;
  bool initialized = false;
  String? token;
  bool isDevMode = false;

  bool get isAuthenticated => user != null;

  Future<void> bootstrap() async {
    loading = true;
    notifyListeners();

    try {
      if (AppConfig.devBypassLogin) {
        await _bootstrapDevMode();
      } else {
        token = await _tokenStorage.getToken();
        user = await _repository.me();
        isDevMode = false;
        error = null;
      }
    } catch (_) {
      user = null;
      token = null;
      isDevMode = false;
    }

    loading = false;
    initialized = true;
    notifyListeners();
  }

  Future<void> _bootstrapDevMode() async {
    final configuredToken = AppConfig.devCustomerToken.trim();
    if (configuredToken.isNotEmpty) {
      await _tokenStorage.saveToken(configuredToken);
      token = configuredToken;
    } else {
      await _tokenStorage.clearToken();
      token = null;
    }

    user = AuthCustomerModel.fromJson(AppConfig.devCustomer);
    isDevMode = true;
    error = null;
  }

  Future<void> enterTestingMode() async {
    await _bootstrapDevMode();
    initialized = true;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final logged = await _repository.loginWithGoogle();
      if (logged == null) {
        error = 'Login dibatalkan.';
        return false;
      }
      user = logged;
      token = await _tokenStorage.getToken();
      isDevMode = false;
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      if (!isDevMode) {
        await _repository.logout();
      } else {
        await _tokenStorage.clearToken();
      }
    } finally {
      user = null;
      token = null;
      isDevMode = false;
      notifyListeners();
    }
  }
}
