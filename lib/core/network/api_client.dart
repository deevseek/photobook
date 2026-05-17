import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const String baseUrl = 'https://profesionalservis.my.id/api/v1';

  final http.Client _client;

  Future<dynamic> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await _client.get(uri);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }

      throw ApiException('Request gagal (${response.statusCode}).');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw const ApiException('Tidak dapat terhubung ke server.');
    }
  }
}
