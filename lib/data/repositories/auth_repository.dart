import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/app_config.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../models/auth_customer_model.dart';

class AuthRepository {
  AuthRepository({ApiClient? apiClient, TokenStorage? tokenStorage}) : _apiClient = apiClient ?? ApiClient(), _tokenStorage = tokenStorage ?? TokenStorage();
  final ApiClient _apiClient; final TokenStorage _tokenStorage;

  GoogleSignIn? _google;

  bool get isGoogleSignInAvailable {
    if (!kIsWeb) return true;
    return AppConfig.googleWebClientId.trim().isNotEmpty;
  }

  GoogleSignIn? _googleClient() {
    if (_google != null) return _google;
    if (kIsWeb && !isGoogleSignInAvailable) return null;
    final clientId = AppConfig.googleWebClientId.trim();
    _google = (kIsWeb && clientId.isNotEmpty) ? GoogleSignIn(clientId: clientId) : GoogleSignIn();
    return _google;
  }

  Future<AuthCustomerModel?> loginWithGoogle() async {
    final google = _googleClient();
    if (google == null) return null;
    final user = await google.signIn();
    if (user == null) return null;
    final payload = {'google_id': user.id, 'name': user.displayName, 'email': user.email, 'avatar': user.photoUrl};
    final data = await _apiClient.post('${ApiConfig.photobookPrefix}/auth/google', body: payload);
    final token = (data['token'] ?? data['access_token'] ?? '').toString();
    if (token.isNotEmpty) await _tokenStorage.saveToken(token);
    final customerJson = (data['customer'] ?? data['user'] ?? <String,dynamic>{}) as Map<String, dynamic>;
    return AuthCustomerModel.fromJson(customerJson);
  }

  Future<AuthCustomerModel> me() async {
    final data = await _apiClient.get('${ApiConfig.photobookPrefix}/auth/me');
    return AuthCustomerModel.fromJson((data is Map<String,dynamic>) ? data : <String,dynamic>{});
  }

  Future<void> logout() async {
    await _apiClient.post('${ApiConfig.photobookPrefix}/auth/logout');
    await _tokenStorage.clearToken();
    await _google?.signOut();
  }
}
