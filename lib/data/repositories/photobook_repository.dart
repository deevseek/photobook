import '../../core/services/api_client.dart';
import '../models/photobook_design_model.dart';
import '../models/photobook_product_model.dart';

class PhotobookRepository {
  PhotobookRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<PhotobookProductModel>> getProducts() async {
    final data = await _apiClient.get('/photobook/products');
    final list = (data is List ? data : <dynamic>[]).whereType<Map<String, dynamic>>().toList();
    return list.map(PhotobookProductModel.fromJson).toList();
  }

  Future<PhotobookProductModel> getProductDetail(int id) async {
    final data = await _apiClient.get('/photobook/products/$id');
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Data detail produk tidak valid.');
    }
    return PhotobookProductModel.fromJson(data);
  }

  Future<List<PhotobookDesignModel>> getDesignsByProduct(int productId) async {
    final data = await _apiClient.get('/photobook/products/$productId/designs');
    final list = (data is List ? data : <dynamic>[]).whereType<Map<String, dynamic>>().toList();
    return list.map(PhotobookDesignModel.fromJson).toList();
  }

  Future<PhotobookDesignModel> getDesignDetail(int id) async {
    final data = await _apiClient.get('/photobook/designs/$id');
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Data detail desain tidak valid.');
    }
    return PhotobookDesignModel.fromJson(data);
  }
}
