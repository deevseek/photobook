import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../models/auth_customer_model.dart';

class AuthRepository {
  AuthRepository({ApiClient? apiClient, TokenStorage? tokenStorage}) : _apiClient = apiClient ?? ApiClient(), _tokenStorage = tokenStorage ?? TokenStorage();
  final ApiClient _apiClient; final TokenStorage _tokenStorage; final GoogleSignIn _google = GoogleSignIn();

  Future<AuthCustomerModel?> loginWithGoogle() async {
    final user = await _google.signIn();
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

  Future<void> logout() async { await _apiClient.post('${ApiConfig.photobookPrefix}/auth/logout'); await _tokenStorage.clearToken(); await _google.signOut(); }
}
