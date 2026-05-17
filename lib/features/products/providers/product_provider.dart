import 'package:flutter/foundation.dart';
import '../../../core/state/view_state.dart';
import '../../../data/models/photobook_product_model.dart';
import '../../../data/repositories/photobook_repository.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider({PhotobookRepository? repository}) : _repository = repository ?? PhotobookRepository();
  final PhotobookRepository _repository;
  ViewStatus status = ViewStatus.idle;
  String? error;
  List<PhotobookProductModel> products = [];

  Future<void> fetchProducts() async {
    status = ViewStatus.loading; error = null; notifyListeners();
    try { products = await _repository.getProducts(); status = products.isEmpty ? ViewStatus.empty : ViewStatus.data; }
    catch (e) { error = e.toString().replaceFirst('Exception: ', ''); status = ViewStatus.error; }
    notifyListeners();
  }
}
