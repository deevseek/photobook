import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/state/view_state.dart';
import '../../../core/storage/token_storage.dart';
import '../../../data/models/photobook_order_model.dart';
import '../../../data/repositories/photobook_repository.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider({PhotobookRepository? repository, TokenStorage? tokenStorage})
      : _repository = repository ?? PhotobookRepository(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final PhotobookRepository _repository;
  final TokenStorage _tokenStorage;
  ViewStatus status = ViewStatus.idle;
  String? error;
  List<PhotobookOrderModel> orders = [];

  Future<void> fetchOrders() async {
    status = ViewStatus.loading;
    error = null;
    notifyListeners();
    try {
      final token = (await _tokenStorage.getToken())?.trim() ?? '';
      final hasDevToken = AppConfig.devBypassLogin && AppConfig.devCustomerToken.trim().isNotEmpty;
      if (token.isEmpty && !hasDevToken) {
        throw Exception('Endpoint ini membutuhkan token customer. Isi AppConfig.devCustomerToken untuk testing order/payment.');
      }
      orders = await _repository.getOrders();
      status = orders.isEmpty ? ViewStatus.empty : ViewStatus.data;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      status = ViewStatus.error;
    }
    notifyListeners();
  }
}
