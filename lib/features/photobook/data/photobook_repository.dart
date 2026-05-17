import '../../../core/network/api_client.dart';
import 'photobook_design_model.dart';
import 'photobook_product_model.dart';

class PhotobookRepository {
  PhotobookRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<PhotobookProductModel>> getProducts() async {
    final result = await _apiClient.get('/photobook/products');
    final list = _extractList(result);
    return list.map(PhotobookProductModel.fromJson).toList();
  }

  Future<PhotobookProductModel> getProductById(int id) async {
    final result = await _apiClient.get('/photobook/products/$id');
    final data = _extractMap(result);
    return PhotobookProductModel.fromJson(data);
  }

  Future<List<PhotobookDesignModel>> getDesignsByProductId(int productId) async {
    final result = await _apiClient.get('/photobook/products/$productId/designs');
    final list = _extractList(result);
    return list.map(PhotobookDesignModel.fromJson).toList();
  }

  Future<PhotobookDesignModel> getDesignById(int id) async {
    final result = await _apiClient.get('/photobook/designs/$id');
    final data = _extractMap(result);
    return PhotobookDesignModel.fromJson(data);
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    final maybeList = raw is List
        ? raw
        : raw is Map<String, dynamic>
            ? (raw['data'] is List ? raw['data'] as List : const [])
            : const [];

    return maybeList
        .whereType<Map>()
        .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
        .toList();
  }

  Map<String, dynamic> _extractMap(dynamic raw) {
    final maybeMap = raw is Map<String, dynamic>
        ? (raw['data'] is Map<String, dynamic> ? raw['data'] as Map<String, dynamic> : raw)
        : <String, dynamic>{};
    return maybeMap;
  }
}
