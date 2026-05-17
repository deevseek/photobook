import 'dart:io';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../config/app_config.dart';
import '../errors/api_exception.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient({Dio? dio, TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage(),
        _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: ApiConfig.timeoutSeconds),
      receiveTimeout: const Duration(seconds: ApiConfig.timeoutSeconds),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _request(() => _dio.get(path, queryParameters: queryParameters));
    return _parseBody(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await _request(() => _dio.post(path, data: body ?? {}));
    return _parseBody(response);
  }

  Future<dynamic> postMultipart(String path, {required FormData formData, ProgressCallback? onSendProgress}) async {
    final response = await _request(() => _dio.post(path, data: formData, onSendProgress: onSendProgress));
    return _parseBody(response);
  }

  Future<Response<dynamic>> _request(Future<Response<dynamic>> Function() fn) async {
    try {
      final storedToken = (await _tokenStorage.getToken())?.trim() ?? '';
      final fallbackDevToken = AppConfig.devBypassLogin ? AppConfig.devCustomerToken.trim() : '';
      final effectiveToken = storedToken.isNotEmpty ? storedToken : fallbackDevToken;

      if (effectiveToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $effectiveToken';
      } else {
        _dio.options.headers.remove('Authorization');
      }

      return await fn();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  dynamic _parseBody(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map<String, dynamic>) throw const ApiException('Format response server tidak valid.');
    if (body['success'] != true) throw ApiException((body['message'] ?? 'Request gagal').toString());
    return body['data'];
  }

  ApiException _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (status == 422 && data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return ApiException(first.first.toString(), statusCode: 422);
      }
      return ApiException((data['message'] ?? 'Validasi gagal').toString(), statusCode: 422);
    }
    if ([401, 403, 404, 500].contains(status)) return ApiException(_extractMessage(data, fallback: 'Request gagal ($status)'), statusCode: status);
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) return const ApiException('Koneksi timeout. Coba lagi.');
    if (e.error is SocketException) return const ApiException('Tidak dapat terhubung ke server.');
    return ApiException(_extractMessage(data, fallback: e.message ?? 'Terjadi kesalahan.'));
  }

  String _extractMessage(dynamic data, {required String fallback}) {
    if (data is Map<String, dynamic> && data['message'] != null) return data['message'].toString();
    return fallback;
  }
}
