import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/errors/api_exception.dart';
import '../../core/services/api_client.dart';
import '../models/payment_response_model.dart';
import '../models/photobook_design_model.dart';
import '../models/photobook_order_model.dart';
import '../models/photobook_product_model.dart';
import '../models/price_calculation_model.dart';
import '../models/shipping_rate_model.dart';
import '../models/tracking_model.dart';

class UploadedProjectPhoto {
  final int photoId;
  final String frameId;
  final int pageNumber;
  final String fileUrl;
  final String filePath;

  const UploadedProjectPhoto({required this.photoId, required this.frameId, required this.pageNumber, required this.fileUrl, required this.filePath});

  factory UploadedProjectPhoto.fromJson(Map<String, dynamic> json) => UploadedProjectPhoto(
        photoId: (json['photo_id'] as num?)?.toInt() ?? 0,
        frameId: (json['frame_id'] ?? '').toString(),
        pageNumber: (json['page_number'] as num?)?.toInt() ?? 0,
        fileUrl: (json['file_url'] ?? '').toString(),
        filePath: (json['file_path'] ?? '').toString(),
      );
}

class PhotobookRepository {
  PhotobookRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();
  final ApiClient _apiClient; String get _p=>ApiConfig.photobookPrefix;
  Future<List<PhotobookProductModel>> getProducts() async {
    final responseData = await _apiClient.get('$_p/products');
    final items = extractListFromApiResponse(responseData);
    debugPrint('PRODUCT API RAW: $responseData');
    debugPrint('PRODUCT API ITEMS COUNT: ${items.length}');
    return items.whereType<Map<String, dynamic>>().map(PhotobookProductModel.fromJson).toList();
  }
  Future<PhotobookProductModel> getProductDetail(int id) async => PhotobookProductModel.fromJson(_toMap(await _apiClient.get('$_p/products/$id')));
  Future<List<PhotobookDesignModel>> getProductDesigns(int productId) async {
    final endpoint = '$_p/products/$productId/designs';
    debugPrint('DESIGN API URL: $endpoint');
    final responseData = await _apiClient.get(endpoint);
    debugPrint('DESIGN API RESPONSE: $responseData');

    final rawData = responseData is Map<String, dynamic> ? responseData['data'] : responseData;

    List<dynamic> items;

    if (rawData is List) {
      items = rawData;
    } else if (rawData is Map && rawData['data'] is List) {
      items = rawData['data'] as List<dynamic>;
    } else {
      items = [];
    }

    return items.whereType<Map<String, dynamic>>().map((item) => PhotobookDesignModel.fromJson(item)).toList();
  }
  Future<List<PhotobookDesignModel>> getDesigns() async => extractListFromApiResponse(await _apiClient.get('$_p/designs')).whereType<Map<String, dynamic>>().map(PhotobookDesignModel.fromJson).toList();
  Future<PhotobookDesignModel> getDesignDetail(int id) async => PhotobookDesignModel.fromJson(_toMap(await _apiClient.get('$_p/designs/$id')));
  Future<String?> downloadIdml(int id) async => _toMap(await _apiClient.get('$_p/designs/$id/download-idml'))['download_url']?.toString();
  Future<PriceCalculationModel> calculatePrice({required int productId,int? contributorDesignId,required int pageCount,required int printQuantity}) async => PriceCalculationModel.fromJson(_toMap(await _apiClient.post('$_p/calculate-price',body:{'product_id':productId,'contributor_design_id':contributorDesignId,'page_count':pageCount,'print_quantity':printQuantity} )));
  Future<PhotobookOrderModel> createOrder(Map<String,dynamic> body) async => PhotobookOrderModel.fromJson(_toMap(await _apiClient.post('$_p/orders',body: body)));
  Future<List<PhotobookOrderModel>> getOrders() async => extractListFromApiResponse(await _apiClient.get('$_p/orders')).whereType<Map<String, dynamic>>().map(PhotobookOrderModel.fromJson).toList();
  Future<PhotobookOrderModel> getOrderDetail(String n) async => PhotobookOrderModel.fromJson(_toMap(await _apiClient.get('$_p/orders/$n')));
  Future<void> saveProject(String n, Map<String,dynamic> pj) async => _apiClient.post('$_p/orders/$n/save-project', body: {'project_json': pj});
  Future<UploadedProjectPhoto> uploadProjectPhoto({required int designId, required String frameId, required int pageNumber, required List<int> bytes, required String filename}) async {
    final formData = FormData.fromMap({
      'design_id': designId,
      'frame_id': frameId,
      'page_number': pageNumber,
      'photo': MultipartFile.fromBytes(bytes, filename: filename),
    });
    return UploadedProjectPhoto.fromJson(_toMap(await _apiClient.postMultipart('$_p/project-photos/upload', formData: formData)));
  }
  Future<void> uploadFinalPdf(String n, File finalPdf, Map<String,dynamic> pj, int pageCount,{ProgressCallback? onSendProgress}) async {final f=FormData.fromMap({'final_pdf':await MultipartFile.fromFile(finalPdf.path,filename:'final.pdf'),'project_json':pj,'page_count':pageCount}); await _apiClient.postMultipart('$_p/orders/$n/upload-final-pdf', formData:f,onSendProgress:onSendProgress);}
  Future<Map<String,dynamic>> getPrintFile(String n) async => _toMap(await _apiClient.get('$_p/orders/$n/print-file'));
  Future<TrackingModel> getTracking(String n) async => TrackingModel.fromJson(await _apiClient.get('$_p/orders/$n/tracking'));
  Future<List<ShippingRateModel>> getShippingRates(Map<String,dynamic> body) async {
    final response = await _apiClient.post('$_p/shipping/rates', body: body);
    final mapped = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final list = mapped['data'] is List ? mapped['data'] as List : (response is List ? response : <dynamic>[]);
    return list.whereType<Map<String, dynamic>>().map(ShippingRateModel.fromJson).toList();
  }
  Future<PaymentResponseModel> createPayment(String n) async {
    final response = await _apiClient.post('$_p/payment/create', body: {'order_number':n});
    final map = _toMap(response);
    final data = map['data'] is Map<String, dynamic> ? map['data'] as Map<String, dynamic> : map;
    return PaymentResponseModel.fromJson(data);
  }
  List<dynamic> extractListFromApiResponse(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      return [];
    }

    final rawData = responseData['data'];

    if (rawData is List) {
      return rawData;
    }

    if (rawData is Map && rawData['data'] is List) {
      return rawData['data'] as List;
    }

    return [];
  }
  Map<String,dynamic> _toMap(dynamic d){if(d is Map<String,dynamic>)return d; throw const ApiException('Format data tidak valid.');}
  List<Map<String,dynamic>> _toList(dynamic d)=> (d is List?d:<dynamic>[]).whereType<Map<String,dynamic>>().toList();
}
