import 'package:flutter/foundation.dart';
import '../../../core/state/view_state.dart';
import '../../../data/models/photobook_order_model.dart';
import '../../../data/repositories/photobook_repository.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider({PhotobookRepository? repository}) : _repository = repository ?? PhotobookRepository();
  final PhotobookRepository _repository;
  ViewStatus status = ViewStatus.idle;
  String? error;
  List<PhotobookOrderModel> orders = [];

  Future<void> fetchOrders() async {
    status = ViewStatus.loading; error = null; notifyListeners();
    try { orders = await _repository.getOrders(); status = orders.isEmpty ? ViewStatus.empty : ViewStatus.data; }
    catch (e) { error = e.toString().replaceFirst('Exception: ', ''); status = ViewStatus.error; }
    notifyListeners();
  }
}
