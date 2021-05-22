import 'package:custed2/core/provider/provider_base.dart';
import 'package:custed2/service/custed_service.dart';
import 'package:flutter/widgets.dart';

class AppProvider extends ProviderBase {
  String _notification;
  Map _changeLog;
  bool _showRealUI = true;
  BuildContext ctx;

  String get notification => _notification;
  Map get changeLog => _changeLog; 
  bool get showRealUI => _showRealUI;

  Future<void> loadLocalData() async {
    final service = CustedService();
    _notification = await service.getNotify();
    _changeLog = await service.getChangeLog();
    _showRealUI = await service.showRealCustedUI();

    notifyListeners();
  }

  void setContext(c) {
    ctx = c;
  }
}
