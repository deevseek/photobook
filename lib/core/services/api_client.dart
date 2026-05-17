import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<dynamic> get(String path, {Map<String, String>? headers}) async {
    final uri = _buildUri(path);
    return _send(() => _client.get(uri, headers: headers));
  }

  Future<dynamic> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = _buildUri(path);
    final resolvedHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };

    return _send(
      () => _client.post(
        uri,
        headers: resolvedHeaders,
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Uri _buildUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${ApiConfig.baseUrl}$normalizedPath');
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(ApiConfig.receiveTimeout);
      return _parseResponse(response);
    } on TimeoutException {
      throw const ApiException('Koneksi terlalu lama. Coba lagi.');
    } on SocketException {
      throw const ApiException('Tidak dapat terhubung ke server. Cek koneksi internet Anda.');
    } on http.ClientException {
      throw const ApiException('Gagal menghubungi server. Silakan coba lagi.');
    }
  }

  dynamic _parseResponse(http.Response response) {
    final decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);

    if (response.statusCode == 401) {
      throw const ApiException('Sesi Anda berakhir. Silakan login kembali.', statusCode: 401);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractMessage(decoded, fallback: 'Request gagal (${response.statusCode}).');
      throw ApiException(message, statusCode: response.statusCode);
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Format response server tidak valid.');
    }

    final success = decoded['success'] == true;
    if (!success) {
      throw ApiException(_extractMessage(decoded, fallback: 'Terjadi kesalahan pada server.'));
    }

    return decoded['data'];
  }

  String _extractMessage(dynamic decoded, {required String fallback}) {
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }
}
