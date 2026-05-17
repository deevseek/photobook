import 'package:flutter/foundation.dart';
import '../../../core/state/view_state.dart';
import '../../../data/models/photobook_design_model.dart';
import '../../../data/repositories/photobook_repository.dart';

class DesignProvider extends ChangeNotifier {
  DesignProvider({PhotobookRepository? repository}) : _repository = repository ?? PhotobookRepository();
  final PhotobookRepository _repository;
  ViewStatus status = ViewStatus.idle;
  String? error;
  List<PhotobookDesignModel> designs = [];

  Future<void> fetchByProduct(int productId) async {
    status = ViewStatus.loading; error = null; notifyListeners();
    try { designs = await _repository.getProductDesigns(productId); status = designs.isEmpty ? ViewStatus.empty : ViewStatus.data; }
    catch (e) { error = e.toString().replaceFirst('Exception: ', ''); status = ViewStatus.error; }
    notifyListeners();
  }
}
